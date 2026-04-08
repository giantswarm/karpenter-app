package basic

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/giantswarm/apptest-framework/v3/pkg/state"
	"github.com/giantswarm/apptest-framework/v3/pkg/suite"
	"github.com/giantswarm/clustertest/v3/pkg/client"
	"github.com/giantswarm/clustertest/v3/pkg/logger"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	v1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/types"
	ctrlclient "sigs.k8s.io/controller-runtime/pkg/client"
)

const (
	isUpgrade = false
)

func TestBasic(t *testing.T) {
	var (
		helmRelease *unstructured.Unstructured
		ociRepoName string
	)

	suite.New().
		// The namespace to install the app into within the workload cluster
		WithInstallNamespace("karpenter").
		// If this is an upgrade test or not.
		// If true, the suite will first install the latest released version of the app before upgrading to the test version
		WithIsUpgrade(isUpgrade).
		WithValuesFile("./values.yaml").
		Tests(func() {
			It("should scale the worker node count when helloworld app is deployed", func() {
				ctx := state.GetContext()
				clusterName := state.GetCluster().Name
				org := state.GetCluster().Organization
				namespace := org.GetNamespace()

				// Get the current number of worker nodes
				wcClient, err := state.GetFramework().WC(clusterName)
				Expect(err).To(BeNil())

				nodes := corev1.NodeList{}
				err = wcClient.List(ctx, &nodes, client.DoesNotHaveLabels{"node-role.kubernetes.io/control-plane"})
				Expect(err).To(BeNil())

				replicaCount := len(nodes.Items) + 1
				expectedReplicas := fmt.Sprintf("%d", replicaCount)

				values, err := parseValuesFile("./test_data/scale_helloworld_values.yaml", &helmReleaseTemplateValues{
					ClusterName: clusterName,
					ExtraValues: map[string]string{
						"ReplicaCount": expectedReplicas,
					},
				})
				Expect(err).To(BeNil())

				// Create OCIRepository for the hello-world chart
				ociRepoName = fmt.Sprintf("%s-hello-world-chart", clusterName)
				err = ensureTestOCIRepository(ctx, state.GetFramework().MC(), ociRepoName, namespace, "hello-world")
				Expect(err).To(BeNil())

				// Create HelmRelease targeting the workload cluster
				helmRelease = newTestHelmRelease(
					fmt.Sprintf("%s-scale-hello-world", clusterName),
					namespace,
					"scale-hello-world",
					"giantswarm",
					clusterName,
					ociRepoName,
					values,
				)

				err = state.GetFramework().MC().Create(ctx, helmRelease)
				Expect(err).To(BeNil())

				// Wait for the HelmRelease to be ready
				Eventually(isHelmReleaseReady(ctx, state.GetFramework().MC(), types.NamespacedName{
					Name:      helmRelease.GetName(),
					Namespace: helmRelease.GetNamespace(),
				})).
					WithTimeout(5 * time.Minute).
					WithPolling(5 * time.Second).
					Should(BeTrue())

				// Wait for the deployment to scale up worker nodes
				Eventually(func() (bool, error) {
					deploymentName := "scale-hello-world"
					helloDeployment := &v1.Deployment{}

					err := wcClient.Get(ctx, ctrlclient.ObjectKey{
						Name:      deploymentName,
						Namespace: "giantswarm",
					},
						helloDeployment,
					)
					if err != nil {
						return false, err
					}

					replicas := fmt.Sprint(helloDeployment.Status.ReadyReplicas)
					logger.Log("Checking for increased replicas. Expected: %s, Actual: %s", expectedReplicas, replicas)
					if replicas == expectedReplicas {
						return true, nil
					}

					// Logging out information about pod conditions
					pods := corev1.PodList{}
					err = wcClient.List(ctx, &pods, ctrlclient.MatchingLabels{"app.kubernetes.io/instance": deploymentName})
					if err != nil {
						return false, err
					}
					podConditionMessages := []string{}
					for _, pod := range pods.Items {
						if pod.Status.Phase != corev1.PodRunning {
							for _, condition := range pod.Status.Conditions {
								if condition.Status != corev1.ConditionTrue && condition.Message != "" {
									podConditionMessages = append(podConditionMessages, fmt.Sprintf("%s='%s'", pod.ObjectMeta.Name, condition.Message))
								}
							}
						}
					}
					logger.Log("Condition messages from non-running deployment pods: %v", podConditionMessages)

					// Logging out information about node status
					nodes := corev1.NodeList{}
					err = wcClient.List(ctx, &nodes, client.DoesNotHaveLabels{"node-role.kubernetes.io/control-plane"})
					if err != nil {
						return false, err
					}
					logger.Log("There are currently '%d' worker nodes", len(nodes.Items))
					for _, node := range nodes.Items {
						logger.Log("Worker node status: NodeName='%s', Taints='%s'", node.ObjectMeta.Name, node.Spec.Taints)
					}

					return false, nil
				}, "15m", "10s").Should(BeTrue())
			})
		}).
		AfterSuite(func() {
			ctx := context.Background()
			err := state.GetFramework().MC().Delete(ctx, helmRelease)
			Expect(err).ShouldNot(HaveOccurred())

			err = deleteTestOCIRepository(ctx, state.GetFramework().MC(), ociRepoName, helmRelease.GetNamespace())
			Expect(err).ShouldNot(HaveOccurred())
		}).
		Run(t, "Basic Test")
}
