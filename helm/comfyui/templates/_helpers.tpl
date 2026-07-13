{{- define "comfyui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "comfyui.fullname" -}}
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

{{- define "comfyui.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "comfyui.labels" -}}
helm.sh/chart: {{ include "comfyui.chart" . }}
{{ include "comfyui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "comfyui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "comfyui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "comfyui-mcp.name" -}}
{{- printf "%s-mcp" (include "comfyui.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "comfyui-mcp.fullname" -}}
{{- printf "%s-mcp" (include "comfyui.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "comfyui-mcp.labels" -}}
helm.sh/chart: {{ include "comfyui.chart" . }}
{{ include "comfyui-mcp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "comfyui-mcp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "comfyui-mcp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "comfyui.namespace" -}}
{{- .Values.namespace.name | default .Release.Namespace }}
{{- end }}

{{- define "comfyui.gpuResource" -}}
{{- if .Values.comfyui.gpu.resourceName }}
{{- .Values.comfyui.gpu.resourceName }}
{{- else }}
{{- $vendor := .Values.comfyui.gpu.vendor | lower }}
{{- if eq $vendor "nvidia" }}
{{- printf "nvidia.com/gpu" }}
{{- else if eq $vendor "amd" }}
{{- printf "amd.com/gpu" }}
{{- else if eq $vendor "intel" }}
{{- printf "gpu.intel.com/i915" }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "comfyui.imagePullSecrets" -}}
{{- if .Values.comfyui.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.comfyui.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{- define "comfyui-mcp.imagePullSecrets" -}}
{{- if .Values.mcp.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.mcp.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{- define "comfyui.pvcName" -}}
{{- if .Values.storage.existingClaim }}
{{- .Values.storage.existingClaim }}
{{- else }}
{{- printf "%s-pvc" (include "comfyui.fullname" .) }}
{{- end }}
{{- end }}
