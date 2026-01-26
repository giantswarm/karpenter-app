{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "karpenter-bundle.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "karpenter-bundle.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "karpenter-bundle.labels.selector" -}}
app.kubernetes.io/name: {{ include "karpenter-bundle.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "karpenter-bundle.labels" -}}
{{ include "karpenter-bundle.labels.selector" . }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
application.giantswarm.io/team: {{ index .Chart.Annotations "io.giantswarm.application.team" | quote }}
giantswarm.io/managed-by: {{ .Release.Name | quote }}
giantswarm.io/cluster: {{ .Values.clusterID | quote }}
helm.sh/chart: {{ include "karpenter-bundle.chart" . | quote }}
{{- end -}}

{{/*
Crossplane config ConfigMap name
*/}}
{{- define "karpenter-bundle.crossplaneConfigName" -}}
{{- printf "%s-crossplane-config" .Values.clusterID -}}
{{- end -}}

{{/*
Karpenter config ConfigMap name
*/}}
{{- define "karpenter-bundle.configMapName" -}}
{{- printf "%s-karpenter-app-config" .Values.clusterID -}}
{{- end -}}

{{/*
Get list of all provided OIDC domains from ConfigMap lookup
Returns a JSON array of OIDC domains
*/}}
{{- define "karpenter-bundle.oidcDomains" -}}
{{- $configMapName := include "karpenter-bundle.crossplaneConfigName" . -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace $configMapName -}}
{{- $oidcDomains := list -}}
{{- if $configMap -}}
  {{- $oidcDomain := index $configMap.data "oidcDomain" | default "" -}}
  {{- if $oidcDomain -}}
    {{- $oidcDomains = append $oidcDomains $oidcDomain -}}
  {{- end -}}
  {{- $oidcDomainsStr := index $configMap.data "oidcDomains" | default "" -}}
  {{- if $oidcDomainsStr -}}
    {{- $additionalDomains := $oidcDomainsStr | fromJson -}}
    {{- $oidcDomains = concat $oidcDomains $additionalDomains -}}
  {{- end -}}
{{- end -}}
{{- compact $oidcDomains | uniq | toJson -}}
{{- end -}}

{{/*
Get accountID from ConfigMap lookup
*/}}
{{- define "karpenter-bundle.accountID" -}}
{{- $configMapName := include "karpenter-bundle.crossplaneConfigName" . -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace $configMapName -}}
{{- if $configMap -}}
{{- index $configMap.data "accountID" | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Get awsPartition from ConfigMap lookup
*/}}
{{- define "karpenter-bundle.awsPartition" -}}
{{- $configMapName := include "karpenter-bundle.crossplaneConfigName" . -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace $configMapName -}}
{{- if $configMap -}}
{{- index $configMap.data "awsPartition" | default "aws" -}}
{{- else -}}
aws
{{- end -}}
{{- end -}}

{{/*
Get base domain from ConfigMap lookup
*/}}
{{- define "karpenter-bundle.baseDomain" -}}
{{- $configMapName := include "karpenter-bundle.crossplaneConfigName" . -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace $configMapName -}}
{{- if $configMap -}}
{{- index $configMap.data "baseDomain" | default "" -}}
{{- end -}}
{{- end -}}

{{/*
Karpenter IAM role ARN
*/}}
{{- define "karpenter-bundle.karpenterRoleArn" -}}
{{- $accountID := include "karpenter-bundle.accountID" . -}}
{{- $awsPartition := include "karpenter-bundle.awsPartition" . -}}
{{- printf "arn:%s:iam::%s:role/%s-karpenter" $awsPartition $accountID .Values.clusterID -}}
{{- end -}}

{{/*
Workers IAM role ARN
*/}}
{{- define "karpenter-bundle.workersIamRole" -}}
{{- if .Values.workersIamRole -}}
{{- .Values.workersIamRole -}}
{{- else -}}
{{- $accountID := include "karpenter-bundle.accountID" . -}}
{{- $awsPartition := include "karpenter-bundle.awsPartition" . -}}
{{- printf "arn:%s:iam::%s:role/nodes-*-%s" $awsPartition $accountID .Values.clusterID -}}
{{- end -}}
{{- end -}}

{{/*
SQS Queue ARN
*/}}
{{- define "karpenter-bundle.sqsQueueArn" -}}
{{- $accountID := include "karpenter-bundle.accountID" . -}}
{{- $awsPartition := include "karpenter-bundle.awsPartition" . -}}
{{- printf "arn:%s:sqs:%s:%s:%s-karpenter" $awsPartition .Values.region $accountID .Values.clusterID -}}
{{- end -}}

{{/*
Fetch crossplane config ConfigMap data
*/}}
{{- define "karpenter-bundle.crossplaneConfigData" -}}
{{- $configMapName := include "karpenter-bundle.crossplaneConfigName" . -}}
{{- $configmap := (lookup "v1" "ConfigMap" .Release.Namespace $configMapName) -}}
{{- $cmvalues := dict -}}
{{- if and $configmap $configmap.data $configmap.data.values -}}
  {{- $cmvalues = fromYaml $configmap.data.values -}}
{{- else if $configmap -}}
  {{- /* ConfigMap exists but uses flat key structure instead of values key */ -}}
  {{- $cmvalues = dict "accountID" (index $configmap.data "accountID" | default "") "awsPartition" (index $configmap.data "awsPartition" | default "aws") "baseDomain" (index $configmap.data "baseDomain" | default "") -}}
  {{- $oidcDomain := index $configmap.data "oidcDomain" | default "" -}}
  {{- $oidcDomains := list -}}
  {{- if $oidcDomain -}}
    {{- $oidcDomains = append $oidcDomains $oidcDomain -}}
  {{- end -}}
  {{- $oidcDomainsStr := index $configmap.data "oidcDomains" | default "" -}}
  {{- if $oidcDomainsStr -}}
    {{- $additionalDomains := $oidcDomainsStr | fromJson -}}
    {{- $oidcDomains = concat $oidcDomains $additionalDomains -}}
  {{- end -}}
  {{- $_ := set $cmvalues "oidcDomains" $oidcDomains -}}
{{- else -}}
  {{- fail (printf "Crossplane config ConfigMap %s not found in namespace %s" $configMapName .Release.Namespace) -}}
{{- end -}}
{{- $cmvalues | toYaml -}}
{{- end -}}

{{/*
Get trust policy statements for all provided OIDC domains
*/}}
{{- define "karpenter-bundle.trustPolicyStatements" -}}
{{- $cmvalues := (include "karpenter-bundle.crossplaneConfigData" .) | fromYaml -}}
{{- $oidcDomains := $cmvalues.oidcDomains | default list -}}
{{- range $index, $oidcDomain := $oidcDomains -}}
{{- if not (eq $index 0) }}, {{ end }}{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:{{ $cmvalues.awsPartition }}:iam::{{ $cmvalues.accountID }}:oidc-provider/{{ $oidcDomain }}"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringLike": {
      "{{ $oidcDomain }}:sub": "system:serviceaccount:*:*karpenter*"
    }
  }
}
{{- end -}}
{{- end -}}

{{/*
Set Giant Swarm specific values.
Injects IAM role ARN annotation and settings based on ConfigMap lookup.
*/}}
{{- define "giantswarm.setValues" -}}
{{- $cmvalues := (include "karpenter-bundle.crossplaneConfigData" .) | fromYaml -}}
{{- $_ := set .Values.serviceAccount.annotations "eks.amazonaws.com/role-arn" (include "karpenter-bundle.karpenterRoleArn" .) -}}

{{- /* Set clusterName in settings if not already set */ -}}
{{- if not .Values.settings.clusterName -}}
{{- $_ := set .Values.settings "clusterName" .Values.clusterID -}}
{{- end -}}

{{- /* Set interruptionQueue in settings */ -}}
{{- if not .Values.settings.interruptionQueue -}}
{{- $_ := set .Values.settings "interruptionQueue" (printf "%s-karpenter" .Values.clusterID) -}}
{{- end -}}

{{- /* Set clusterID and baseDomain for the karpenter chart */ -}}
{{- if not .Values.clusterID -}}
{{- $_ := set .Values "clusterID" .Values.clusterID -}}
{{- end -}}
{{- if not .Values.baseDomain -}}
{{- $_ := set .Values "baseDomain" ($cmvalues.baseDomain | default "") -}}
{{- end -}}
{{- if not .Values.aws.accountID -}}
{{- $_ := set .Values.aws "accountID" $cmvalues.accountID -}}
{{- end -}}
{{- end -}}

{{/*
Filter values for karpenter chart - exclude bundle-specific values
*/}}
{{- define "karpenter-bundle.karpenterValues" -}}
{{- $excludeKeys := list "clusterID" "region" "workersIamRole" "ociRepositoryUrl" -}}
{{- $values := dict -}}
{{- range $key, $value := .Values -}}
  {{- if not (has $key $excludeKeys) -}}
    {{- $_ := set $values $key $value -}}
  {{- end -}}
{{- end -}}
{{- $values | toYaml -}}
{{- end -}}
