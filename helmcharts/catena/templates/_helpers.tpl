{{/*
Expand the name of the chart.
*/}}
{{- define "catena.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "catena.fullname" -}}
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
{{- define "catena.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "catena.labels" -}}
helm.sh/chart: {{ include "catena.chart" . }}
{{ include "catena.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "catena.selectorLabels" -}}
app.kubernetes.io/name: {{ include "catena.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "catena.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "catena.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the tag name from connection/example and tag override
*/}}
{{- define "catena.image.tag" -}}
{{- if .Values.image.tag }}
{{- .Values.image.tag }}
{{- else }}
{{- $tag := printf "%s-%s" .Values.image.example .Values.image.connection }}
{{- if .Values.image.develop }}
{{- printf "%s-dev" $tag }}
{{- else }}
{{- $tag }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the liveness probe based on connection
*/}}
{{- define "catena.image.live" }}
{{- if .Values.livenessProbe }}
{{- toYaml .Values.livenessProbe }}
{{- else if eq .Values.image.connection "gRPC" -}}
exec:
  command: ["/healthcheck.sh"]
{{- else if eq .Values.image.connection "REST" -}}
httpGet:
  path: /st2138-api/v1/health
  port: http
{{- end }}
{{- end }}

{{/*
Create the ingress host out of host or hostBase and example/connection
*/}}
{{- define "catena.ingress.host" }}
{{- if .Values.ingress.hostBase }}
{{- printf "%s-%s.%s" .Values.image.example .Values.image.connection .Values.ingress.hostBase | lower | quote }}
{{- else }}
{{- .Values.ingress.host | lower | quote }}
{{- end }}
{{- end }}