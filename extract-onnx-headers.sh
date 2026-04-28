#!/bin/bash
# Extract ONNX Runtime headers from official release package or source code
# This script extracts only the public API header files needed for development
#
# Usage:
#   ./extract-onnx-headers.sh <source_dir> <output_dir> [version]
#
# Examples:
#   From official release: ./extract-onnx-headers.sh /path/to/onnxruntime-linux-x64-1.25.1 /tmp/headers 1.25.1
#   From source code:      ./extract-onnx-headers.sh /opt/onnxruntime /tmp/headers 1.25.1

set -e

SOURCE_DIR="${1:-}"
OUTPUT_DIR="${2:-/tmp/onnx-headers}"
VERSION="${3:-1.25.1}"

if [ -z "${SOURCE_DIR}" ]; then
    echo "❌ Error: Source directory not specified"
    echo "Usage: $0 <source_dir> <output_dir> [version]"
    exit 1
fi

echo "📦 Extracting ONNX Runtime v${VERSION} headers..."
echo "   Source: ${SOURCE_DIR}"
echo "   Output: ${OUTPUT_DIR}"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Check if this is an official release package (has include directory with public headers)
if [ -d "${SOURCE_DIR}/include" ] && [ -f "${SOURCE_DIR}/include/onnxruntime_c_api.h" ]; then
    echo "✅ Detected official release package structure"
    
    # Copy entire include directory (official structure)
    cp -r "${SOURCE_DIR}/include" "${OUTPUT_DIR}/"
    
    # Count header files
    HEADER_COUNT=$(find "${OUTPUT_DIR}/include" -name "*.h" | wc -l)
    echo "   Total public API header files: ${HEADER_COUNT}"
    
    echo "✅ Headers extracted successfully (official release)"
    
elif [ -d "${SOURCE_DIR}/include/onnxruntime" ]; then
    echo "⚠️  Detected source code structure (extracting public API headers only)"
    
    # Create include directory structure
    mkdir -p "${OUTPUT_DIR}/include/core/providers"
    
    # Copy only public API headers from source
    PUBLIC_HEADERS=(
        "cpu_provider_factory.h"
        "onnxruntime_c_api.h"
        "onnxruntime_cxx_api.h"
        "onnxruntime_cxx_inline.h"
        "onnxruntime_env_config_keys.h"
        "onnxruntime_ep_c_api.h"
        "onnxruntime_ep_device_ep_metadata_keys.h"
        "onnxruntime_float16.h"
        "onnxruntime_lite_custom_op.h"
        "onnxruntime_run_options_config_keys.h"
        "onnxruntime_session_options_config_keys.h"
        "provider_options.h"
    )
    
    SOURCE_INCLUDE="${SOURCE_DIR}/include/onnxruntime"
    
    for header in "${PUBLIC_HEADERS[@]}"; do
        if [ -f "${SOURCE_INCLUDE}/${header}" ]; then
            cp "${SOURCE_INCLUDE}/${header}" "${OUTPUT_DIR}/include/"
            echo "   ✅ ${header}"
        else
            echo "   ⚠️  Missing: ${header}"
        fi
    done
    
    # Copy provider headers
    if [ -f "${SOURCE_INCLUDE}/core/providers/custom_op_context.h" ]; then
        cp "${SOURCE_INCLUDE}/core/providers/custom_op_context.h" "${OUTPUT_DIR}/include/core/providers/"
        echo "   ✅ core/providers/custom_op_context.h"
    fi
    
    if [ -f "${SOURCE_INCLUDE}/core/providers/resource.h" ]; then
        cp "${SOURCE_INCLUDE}/core/providers/resource.h" "${OUTPUT_DIR}/include/core/providers/"
        echo "   ✅ core/providers/resource.h"
    fi
    
    HEADER_COUNT=$(find "${OUTPUT_DIR}/include" -name "*.h" | wc -l)
    echo "   Total public API header files: ${HEADER_COUNT}"
    
    echo "✅ Headers extracted successfully (from source)"
else
    echo "❌ Include directory not found in: ${SOURCE_DIR}"
    echo "   Expected: ${SOURCE_DIR}/include/onnxruntime_c_api.h"
    echo "   Or: ${SOURCE_DIR}/include/onnxruntime/"
    exit 1
fi

# Show directory structure
echo ""
echo "📁 Header directory structure:"
find "${OUTPUT_DIR}/include" -type d | head -20

# Create tarball
TARBALL="onnxruntime-headers-${VERSION}.tar.gz"
echo ""
echo "🗜️ Creating tarball: ${TARBALL}"
cd "${OUTPUT_DIR}"
tar --no-xattrs -czf "${TARBALL}" include/

echo "✅ Tarball created: ${OUTPUT_DIR}/${TARBALL}"
ls -lh "${OUTPUT_DIR}/${TARBALL}"

# Generate checksum
if command -v sha256sum &> /dev/null; then
    sha256sum "${OUTPUT_DIR}/${TARBALL}" > "${OUTPUT_DIR}/${TARBALL}.sha256"
elif command -v shasum &> /dev/null; then
    shasum -a 256 "${OUTPUT_DIR}/${TARBALL}" > "${OUTPUT_DIR}/${TARBALL}.sha256"
fi
if [ -f "${OUTPUT_DIR}/${TARBALL}.sha256" ]; then
    echo "✅ Checksum: $(cat "${OUTPUT_DIR}/${TARBALL}.sha256")"
fi

echo ""
echo "🎉 Done! Headers ready for use."
