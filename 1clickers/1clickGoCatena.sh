#!/usr/bin/env bash

set -e

PROJECT_NAME="catena-go-demo-device"
PORT="6255"

echo "========================================="
echo " Catena One-Click Demo Device Setup"
echo "========================================="

# --------------------------------------------------
# Detect OS
# --------------------------------------------------

OS="$(uname -s)"

echo ""
echo "Detected OS: $OS"

# --------------------------------------------------
# Install Go if missing
# --------------------------------------------------

if ! command -v go >/dev/null 2>&1; then
    echo ""
    echo "Go is not installed."

    case "$OS" in
        Linux*)
            echo "Installing Go..."

            if command -v apt >/dev/null 2>&1; then
                sudo apt update
                sudo apt install -y golang-go
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y golang
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y golang
            else
                echo "Unsupported Linux package manager."
                echo "Please install Go manually:"
                echo "https://go.dev/doc/install"
                exit 1
            fi
            ;;
        Darwin*)
            echo "Installing Go via Homebrew..."

            if ! command -v brew >/dev/null 2>&1; then
                echo "Homebrew not found."
                echo "Install Homebrew first:"
                echo "https://brew.sh"
                exit 1
            fi

            brew install go
            ;;
        *)
            echo "Unsupported OS."
            echo "Please install Go manually:"
            echo "https://go.dev/doc/install"
            exit 1
            ;;
    esac
fi

echo ""
echo "Go version:"
go version

# --------------------------------------------------
# Create project
# --------------------------------------------------

echo ""
echo "Creating project..."

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# --------------------------------------------------
# Initialize module
# --------------------------------------------------

echo ""
echo "Initializing Go module..."
if [ -f go.mod ]; then
    echo "go.mod already exists, skipping 'go mod init'."
else
    go mod init "$PROJECT_NAME"
fi

# --------------------------------------------------
# Install Catena SDK
# --------------------------------------------------

echo ""
echo "Installing Catena Go SDK..."

go get github.com/rossvideo/catena/sdks/go@v0.0.0-20260713174137-358d411d9b7a

# --------------------------------------------------
# Write demo application
# --------------------------------------------------

echo ""
echo "Generating main.go..."

cat > main.go <<EOF
package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"sync"
	"time"

	"github.com/rossvideo/catena/sdks/go/pkg/catena"
	"github.com/rossvideo/catena/sdks/go/pkg/logger"
	"github.com/rossvideo/catena/sdks/go/pkg/transports"
)

func main() {
	// _, err := config.InitOptions("go test",os.Args)
	closelogger, err := logger.Init(logger.DefaultLoggerOptions())
	if err != nil {
		log.Fatal(err)
	}
	defer closelogger()

	jwtOptions := catena.JwtValidationOptions{}
	srvoptions := catena.ServerOptions{
		MaxConnections: 4,
		AuthzEnabled:   false,
		JwtOptions:     jwtOptions,
	}
	srv, err := catena.NewServer(srvoptions)
	if err != nil {
		log.Fatal(err)
	}

	slot0 := struct {
		mu      sync.RWMutex
		hello   string
		counter int32
		product map[string]any
	}{
		hello:   "Hello World!",
		counter: 0,
		product: map[string]any{
			"name":               "Good Device",
			"vendor":             "Ross Video",
			"version":            "1.0.0",
			"catena_sdk":         "github.com/rossvideo/catena/sdks/go",
			"catena_sdk_version": "v0.1.0",
			"serial_number":      "WORLD001",
		},
	}

	go func() {
		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()
		for range ticker.C {
			slot0.mu.Lock()
			slot0.counter++
			if slot0.counter > 200 {
				slot0.counter = 0
			}
			slot0.mu.Unlock()

			srv.BroadcastUpdate(0, "counter", slot0.counter, catena.ScopeAdm)

		}
	}()
	// -------------
	// GetDevice
	// -------------
	srv.RegisterGetDeviceHandler(0, func(slot uint16, context catena.HandlerContext) (catena.Device, catena.StatusResult) {
		slot0.mu.RLock()
		defer slot0.mu.RUnlock()

		deviceInfo := map[string]any{
			"slot":              uint32(0),
			"detail_level":      catena.DetailLevelFull,
			"multi_set_enabled": true,
			"subscriptions":     true,
			"params": map[string]any{
				"product": map[string]any{
					"type":      catena.ParamTypeStruct,
					"read_only": true,
					"params": map[string]any{
						"name": map[string]any{
							"type":      catena.ParamTypeString,
							"read_only": true,
						},
						"vendor": map[string]any{
							"type":      catena.ParamTypeString,
							"read_only": true,
						},
						"version": map[string]any{
							"type":      catena.ParamTypeString,
							"read_only": true,
						},
						"catena_sdk": map[string]any{
							"type":      catena.ParamTypeString,
							"read_only": true,
						},
						"catena_sdk_version": map[string]any{
							"type":      catena.ParamTypeString,
							"read_only": true,
						},
						"serial_number": map[string]any{
							"type":      catena.ParamTypeString,
							"read_only": true,
						},
					},
					"value": map[string]any{
						"struct_value": map[string]any{
							"fields": map[string]any{
								"name": map[string]any{
									"string_value": slot0.product["name"],
								},
								"vendor": map[string]any{
									"string_value": slot0.product["vendor"],
								},
								"version": map[string]any{
									"string_value": slot0.product["version"],
								},
								"catena_sdk": map[string]any{
									"string_value": slot0.product["catena_sdk"],
								},
								"catena_sdk_version": map[string]any{
									"string_value": slot0.product["catena_sdk_version"],
								},
								"serial_number": map[string]any{
									"string_value": slot0.product["serial_number"],
								},
							},
						},
					},
				},
				"hello_world_txt": map[string]any{
					"name": map[string]any{
						"display_strings": map[string]string{
							"en": "Hello World Text",
						},
					},
					"type": catena.ParamTypeString,
					"value": map[string]any{
						"string_value": slot0.hello,
					},
				},
				"counter": map[string]any{
					"name": map[string]any{
						"display_strings": map[string]string{
							"en": "Counter",
						},
					},
					"type": catena.ParamTypeInt32,
					"value": map[string]any{
						"int32_value": slot0.counter,
					},
				},
			},
		}

		device, err := catena.ToDevice(deviceInfo)
		if err != nil {
			return catena.ReplyError[catena.Device](catena.StatusCodeInternal, err.Error())
		}

		return catena.Reply(device)
	})

	// -------------
	// ParamInfo
	// -------------
	srv.RegisterParamInfoHandler(0, func(slot uint16, fqoid string, recursive bool, ctx catena.HandlerContext) ([]catena.ParamInfo, catena.StatusResult) {
		_ = slot
		var info catena.ParamInfo
		switch fqoid {
		case "product":
			info = catena.NewParamInfo("product", catena.NewPolyglotText(), catena.ParamTypeStruct, "", 0)
		case "product/name":
			info = catena.NewParamInfo("product/name", catena.NewPolyglotText(), catena.ParamTypeString, "", 0)
		case "product/vendor":
			info = catena.NewParamInfo("product/vendor", catena.NewPolyglotText(), catena.ParamTypeString, "", 0)
		case "product/version":
			info = catena.NewParamInfo("product/version", catena.NewPolyglotText(), catena.ParamTypeString, "", 0)
		case "product/catena_sdk":
			info = catena.NewParamInfo("product/catena_sdk", catena.NewPolyglotText(), catena.ParamTypeString, "", 0)
		case "product/catena_sdk_version":
			info = catena.NewParamInfo("product/catena_sdk_version", catena.NewPolyglotText(), catena.ParamTypeString, "", 0)
		case "product/serial_number":
			info = catena.NewParamInfo("product/serial_number", catena.NewPolyglotText(), catena.ParamTypeString, "", 0)
		case "hello_world_txt":
			info = catena.NewParamInfo("hello_world_txt", catena.NewPolyglotText(), catena.ParamTypeString, "", 0)
		case "/counter":
			info = catena.NewParamInfo("/counter", catena.NewPolyglotText(), catena.ParamTypeInt32, "", 0)
		default:
			return nil, catena.StatusWithCode(catena.StatusCodeNotFound, "parameter not found: "+fqoid)
		}
		return []catena.ParamInfo{info}, catena.StatusWithCode(catena.StatusCodeOk, "")
	})

	// -----------
	// GetValue
	// -----------
	srv.RegisterGetValueHandler(0, func(slot uint16, fqoid string, context catena.HandlerContext) (catena.Value, catena.StatusResult) {
		_ = slot
		slot0.mu.RLock()
		defer slot0.mu.RUnlock()
		var v catena.Value
		var res catena.StatusResult
		switch fqoid {
		case "product":
			v, res = catena.ToValue(slot0.product)
		case "product/name":
			v, res = catena.ToValue(slot0.product["name"])
		case "product/vendor":
			v, res = catena.ToValue(slot0.product["vendor"])
		case "product/version":
			v, res = catena.ToValue(slot0.product["version"])
		case "product/catena_sdk":
			v, res = catena.ToValue(slot0.product["catena_sdk"])
		case "product/catena_sdk_version":
			v, res = catena.ToValue(slot0.product["catena_sdk_version"])
		case "product/serial_number":
			v, res = catena.ToValue(slot0.product["serial_number"])
		case "hello_world_txt":
			v, res = catena.ToValue(slot0.hello)
		case "counter":
			v, res = catena.ToValue(slot0.counter)
		}
		if res.Code != catena.StatusCodeOk {
			return catena.ReplyError[catena.Value](catena.StatusCodeInternal, res.Error)
		}
		return catena.Reply(v)
	})

	// ----------
	// SetValue
	// ----------

	srv.RegisterSetValueHandler(0, func(slot uint16, entries []catena.SetValueEntry, context catena.HandlerContext) catena.StatusResult {
		_ = slot
		_ = context
		slot0.mu.Lock()
		defer slot0.mu.Unlock()

		for _, entry := range entries {
			switch entry.Fqoid {
			case "hello_world_txt":
				if _, ok := entry.Value.(string); !ok {
					return catena.StatusWithCode(catena.StatusCodeInvalidArgument, fmt.Sprintf(entry.Fqoid+" must be a valid type got type %T", entry.Value))
				}
			case "counter":
				if _, ok := entry.Value.(int32); !ok {
					return catena.StatusWithCode(catena.StatusCodeInvalidArgument, fmt.Sprintf(entry.Fqoid+" must be a valid type got type %T", entry.Value))
				}
			case "product", "product/name", "product/vendor", "product/version", "product/catena_sdk", "product/catena_sdk_version", "product/serial_number":
				return catena.StatusWithCode(catena.StatusCodePermissionDenied, "protected parameter: "+entry.Fqoid)
			default:
				return catena.StatusWithCode(catena.StatusCodeNotFound, "parameter not found: "+entry.Fqoid)
			}
		}

		for _, entry := range entries {
			switch entry.Fqoid {
			case "hello_world_txt":
				slot0.hello = entry.Value.(string)
			case "counter":
				slot0.counter = entry.Value.(int32)
			}
			srv.BroadcastUpdate(0, entry.Fqoid, entry.Value, catena.ScopeAdm)
		}

		return catena.StatusWithCode(catena.StatusCodeOk, "")
	})

	if err := srv.RegisterTransport(transports.NewRestTransport(transports.RestOptions{Port: 6255})); err != nil {
		log.Fatal(err)
	}

	log.Println("=================================")
	log.Println(" Catena REST Device Running")
	log.Println(" http://localhost:6255")
	log.Println("=================================")

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	<-ctx.Done()

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	srv.Shutdown(shutdownCtx)
}



EOF

# --------------------------------------------------
# Download dependencies
# --------------------------------------------------

echo ""
echo "Downloading dependencies..."

go mod tidy

# --------------------------------------------------
# Build app
# --------------------------------------------------

echo ""
echo "Building demo device..."

go build -o catena-demo-device

# --------------------------------------------------
# Finished
# --------------------------------------------------

echo ""
echo "========================================="
echo " Setup Complete"
echo "========================================="
echo ""
echo "Project directory:"
echo "  $(pwd)"
echo ""
echo "Run the demo:"
echo ""
echo "  ./catena-demo-device"
echo ""
echo "REST endpoint:"
echo "  http://localhost:${PORT}"
echo ""
echo "Example endpoints:"
echo "  http://localhost:${PORT}/st2138-api/v1/devices"
echo "  http://localhost:${PORT}/st2138-api/v1/0"
echo "  http://localhost:${PORT}/st2138-api/v1/0/value/counter"
echo ""
echo "Done."

echo ""
if [ -t 0 ]; then
	read -r -p "Start the demo device now? [y/N]: " START_DEMO
	case "$START_DEMO" in
		[yY]|[yY][eE][sS])
			echo ""
			echo "Starting demo device on http://localhost:${PORT} ..."
			./catena-demo-device
			;;
		*)
			echo ""
			echo "You can start it later with: ./catena-demo-device"
			;;
	esac
else
	echo "Non-interactive shell detected. Start later with: ./catena-demo-device"
fi