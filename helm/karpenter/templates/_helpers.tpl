{{/*
Expand the name of the chart.
*/}}
{{- define "karpenter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "karpenter.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "karpenter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "karpenter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "karpenter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "karpenter.labels" -}}
helm.sh/chart: {{ include "karpenter.chart" . }}
application.giantswarm.io/team: {{ index .Chart.Annotations "application.giantswarm.io/team" | default "phoenix" | quote }}
giantswarm.io/managed-by: {{ .Release.Name | quote }}
giantswarm.io/service-type: managed
{{ include "karpenter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ include "karpenter.name" . }}
{{- with .Values.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}

{{- define "karpenter.serviceAccountName" -}}
{{- $create := false }}
{{- $saname := "" }}
{{- if .Values.karpenter }}
{{- $create := .Values.karpenter.serviceAccount.create }}
{{- $saname := .Values.karpenter.serviceAccount.name }}
{{- else }}
{{- $create := .Values.serviceAccount.create }}
{{- $saname := .Values.serviceAccount.name }}
{{- end }}
{{- if $create }}
{{- default (include "karpenter.fullname" .) $saname }}
{{- else }}
{{- default "karpenter" $saname }}
{{- end }}
{{- end }}

{{/*
Karpenter image to use
*/}}
{{- define "karpenter.controller.image" -}}
{{- if .Values.controller.image.digest }}
{{- printf "%s:%s@%s" .Values.controller.image.repository  (default (printf "v%s" .Chart.AppVersion) .Values.controller.image.tag) .Values.controller.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.controller.image.repository  (default (printf "v%s" .Chart.AppVersion) .Values.controller.image.tag) }}
{{- end }}
{{- end }}

{{/*
Karpenter renewer image to use
*/}}
{{- define "karpenter.renewer.image" -}}
{{- printf "%s:%s" .Values.renewerCronjob.image.repository  .Values.renewerCronjob.image.tag }}
{{- end }}

{{/* Get PodDisruptionBudget API Version */}}
{{- define "karpenter.pdb.apiVersion" -}}
{{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
{{- print "policy/v1" -}}
{{- else -}}
{{- print "policy/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Flatten Settings Map using "." syntax
*/}}
{{- define "flattenSettings" -}}
{{- $map := first . -}}
{{- $label := last . -}}
{{- range $key := (keys $map | uniq | sortAlpha) }}
  {{- $sublabel := $key -}}
  {{- $val := (get $map $key) -}}
  {{- if $label -}}
    {{- $sublabel = list $label $key | join "." -}}
  {{- end -}}
  {{/* Special-case "tags" since we want this to be a JSON object */}}
  {{- if eq $key "tags" -}}
    {{- if not (kindIs "invalid" $val) -}}
      {{- $sublabel | quote | nindent 2 }}: {{ $val | toJson | quote }}
    {{- end -}}
  {{- else if kindOf $val | eq "map" -}}
    {{- list $val $sublabel | include "flattenSettings" -}}
  {{- else -}}
  {{- if not (kindIs "invalid" $val) -}}
    {{- $sublabel | quote | nindent 2 -}}: {{ $val | quote }}
  {{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Flatten the stdout logging outputs from args provided
*/}}
{{- define "karpenter.controller.outputPathsList" -}}
{{ $paths := list -}}
{{- range .Values.controller.outputPaths -}}
    {{- $paths = printf "%s" . | quote  | append $paths -}}
{{- end -}}
{{ $paths | join ", " }}
{{- end -}}

{{/*
Flatten the stderr logging outputs from args provided
*/}}
{{- define "karpenter.controller.errorOutputPathsList" -}}
{{ $paths := list -}}
{{- range .Values.controller.errorOutputPaths -}}
    {{- $paths = printf "%s" . | quote  | append $paths -}}
{{- end -}}
{{ $paths | join ", " }}
{{- end -}}


{{- define "giantswarm.irsa.annotation" -}}
{{- if (or (eq .Values.aws.region "cn-north-1") (eq .Values.aws.region "cn-northwest-1"))}}
eks.amazonaws.com/role-arn: arn:aws-cn:iam::{{ .Values.aws.accountID }}:role/{{ .Values.clusterID }}-Karpenter-Role
{{- else }}
eks.amazonaws.com/role-arn: arn:aws:iam::{{ .Values.aws.accountID }}:role/{{ .Values.clusterID }}-Karpenter-Role
{{- end -}}
{{- end -}}
