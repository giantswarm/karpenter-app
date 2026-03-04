{{/* vim: set filetype=mustache: */}}
{{/*
Common labels for GiantSwarm extras resources
*/}}
{{- define "karpenter.labels" -}}
app.kubernetes.io/name: karpenter
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
giantswarm.io/service-type: "managed"
application.giantswarm.io/team: {{ index .Chart.Annotations "io.giantswarm.application.team" | quote }}
{{- end -}}

{{/*
Selector labels matching the upstream subchart pods
*/}}
{{- define "karpenter.selectorLabels" -}}
app.kubernetes.io/name: karpenter
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
