package basic

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/giantswarm/apiextensions-application/api/v1alpha1"
	"github.com/giantswarm/apptest-framework/v2/pkg/state"
	"github.com/giantswarm/apptest-framework/v2/pkg/suite"
	"github.com/giantswarm/clustertest/v2/pkg/application"
	"github.com/giantswarm/clustertest/v2/pkg/client"
	"github.com/giantswarm/clustertest/v2/pkg/logger"
	"github.com/giantswarm/clustertest/v2/pkg/wait"
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	v1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/types"
	ctrlclient "sigs.k8s.io/controller-runtime/pkg/client"
)

const (
	isUpgrade = false
)

func TestBasic(t *testing.T) {
	var (
		helloApp *application.Application
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
				// Get the current number of worker nodes
				wcClient, err := state.GetFramework().WC(state.GetCluster().Name)
				Expect(err).To(BeNil())

				nodes := corev1.NodeList{}
				err = wcClient.List(state.GetContext(), &nodes, client.DoesNotHaveLabels{"node-role.kubernetes.io/control-plane"})
				Expect(err).To(BeNil())

				helloAppValues := map[string]string{
					"ReplicaCount": fmt.Sprintf("%d", len(nodes.Items)+1),
				}

				helloApp = application.New(fmt.Sprintf("%s-scale-hello-world", state.GetCluster().Name), "hello-world").
					WithCatalog("giantswarm").
					WithOrganization(*state.GetCluster().Organization).
					WithVersion("latest").
					WithClusterName(state.GetCluster().Name).
					WithInCluster(false).
					WithInstallNamespace("giantswarm").
					MustWithValuesFile("./test_data/scale_helloworld_values.yaml", &application.TemplateValues{
						ClusterName:  state.GetCluster().Name,
						Organization: state.GetCluster().Organization.Name,
						ExtraValues:  helloAppValues,
					})

				err = state.GetFramework().MC().DeployApp(state.GetContext(), *helloApp)
				Expect(err).To(BeNil())

				Eventually(func() (bool, error) {
					managementClusterKubeClient := state.GetFramework().MC()

					helloApplication := &v1alpha1.App{}
					err := managementClusterKubeClient.Get(state.GetContext(), types.NamespacedName{Name: helloApp.InstallName, Namespace: helloApp.GetNamespace()}, helloApplication)
					if err != nil {
						return false, err
					}

					return wait.IsAppDeployed(state.GetContext(), state.GetFramework().MC(), helloApp.InstallName, helloApp.GetNamespace())()
				}).
					WithTimeout(5 * time.Minute).
					WithPolling(5 * time.Second).
					Should(BeTrue())

				Eventually(func() (bool, error) {
					deploymentName := "scale-hello-world"
					helloDeployment := &v1.Deployment{}

					err := wcClient.Get(state.GetContext(), ctrlclient.ObjectKey{
						Name:      deploymentName,
						Namespace: helloApp.InstallNamespace,
					},
						helloDeployment,
					)
					if err != nil {
						return false, err
					}

					replicas := fmt.Sprint(helloDeployment.Status.ReadyReplicas)
					logger.Log("Checking for increased replicas. Expected: %s, Actual: %s", helloAppValues["ReplicaCount"], replicas)
					if replicas == helloAppValues["ReplicaCount"] {
						return true, nil
					}

					// Logging out information about pod conditions
					pods := corev1.PodList{}
					err = wcClient.List(state.GetContext(), &pods, ctrlclient.MatchingLabels{"app.kubernetes.io/instance": deploymentName})
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
					err = wcClient.List(state.GetContext(), &nodes, client.DoesNotHaveLabels{"node-role.kubernetes.io/control-plane"})
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
			err := state.GetFramework().MC().DeleteApp(context.Background(), *helloApp)
			Expect(err).ShouldNot(HaveOccurred())
		}).
		Run(t, "Basic Test")
}
