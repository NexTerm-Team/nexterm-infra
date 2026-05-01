{{/* Полное имя release. */}}
{{- define "nexterm-web.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "nexterm-web.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels */}}
{{- define "nexterm-web.labels" -}}
app.kubernetes.io/name: {{ include "nexterm-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{- define "nexterm-web.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nexterm-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
