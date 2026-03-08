#!/bin/sh
set -eu

OPENEDX_ROOT="/openedx-root"
WORKSPACE_ROOT="/workspace-root"
BRAND_STATIC_DIR="/brand-static"
BRAND_WORKDIR="/brand-workdir"
PARAGON_OUTPUT_DIR="/compiled-themes"
PARAGON_BUILDER_DIR="/paragon-builder"
TMP_PARAGON_DIR="$BRAND_WORKDIR/paragon-build"
TMP_BRAND_DIR="$BRAND_WORKDIR/repository"

has_themes() {
    for arg in "$@"; do
        [ "$arg" = "--themes" ] && return 0
    done
    return 1
}

parse_args() {
    if [ "$#" -lt 4 ]; then
        echo "Error: Expected at least 4 args, got $#. Must run via tutor."
        exit 1
    fi

    shift 3

    if ! has_themes "$@"; then
        if [ -n "${PARAGON_ENABLED_THEMES:-}" ]; then
            set -- "$@" --themes "${PARAGON_ENABLED_THEMES}"
        fi
    fi

    printf '%s\n' "$@"
}

resolve_brand_repository() {
    local candidate="$OPENEDX_ROOT/$BRAND_REPOSITORY"
    local workspace_candidate="$WORKSPACE_ROOT/$BRAND_REPOSITORY"

    if [ -d "$candidate/.git" ] || [ -f "$candidate/package.json" ] || [ -d "$candidate/paragon" ]; then
        echo "Using local brand repository: $candidate"
        cp -a "$candidate/." "$TMP_BRAND_DIR/"
        return 0
    fi

    if [ -d "$workspace_candidate/.git" ] || [ -f "$workspace_candidate/package.json" ] || [ -d "$workspace_candidate/paragon" ]; then
        echo "Using workspace brand repository: $workspace_candidate"
        cp -a "$workspace_candidate/." "$TMP_BRAND_DIR/"
        return 0
    fi

    echo "Cloning brand repository: $BRAND_REPOSITORY"
    git clone "$BRAND_REPOSITORY" "$TMP_BRAND_DIR"
    (
        cd "$TMP_BRAND_DIR"
        git checkout "$BRAND_VERSION"
    )
}

build_css_bundle() {
    local index_css_file="$1"
    local bundle_directory
    local bundle_name
    local minified_output_file
    local overrides_file
    local working_css_file

    bundle_directory="$(dirname "$index_css_file")"
    bundle_name="$(basename "$bundle_directory")"
    minified_output_file="$bundle_directory/${bundle_name}.min.css"
    working_css_file="$index_css_file"

    if [ "$bundle_name" = "core" ]; then
        overrides_file="$TMP_BRAND_DIR/paragon/overrides/core.css"
    else
        overrides_file="$TMP_BRAND_DIR/paragon/overrides/themes/${bundle_name}.css"
    fi

    if [ -f "$overrides_file" ]; then
        working_css_file="$bundle_directory/${bundle_name}.with-overrides.css"
        cat "$index_css_file" "$overrides_file" > "$working_css_file"
    fi

    npx --prefix "$PARAGON_BUILDER_DIR" postcss "$working_css_file" \
        --use postcss-import \
        --use postcss-custom-media \
        --use postcss-combine-duplicated-selectors \
        --use postcss-minify \
        --no-map \
        --output "$minified_output_file"
}

copy_brand_asset_if_relative() {
    local asset_value="$1"

    [ -z "$asset_value" ] && return 0

    case "$asset_value" in
        http://*|https://*)
            return 0
            ;;
        *)
            if [ -f "$TMP_BRAND_DIR/$asset_value" ]; then
                mkdir -p "$BRAND_STATIC_DIR/$(dirname "$asset_value")"
                cp -a "$TMP_BRAND_DIR/$asset_value" "$BRAND_STATIC_DIR/$asset_value"
            fi
            ;;
    esac
}

set -- $(parse_args "$@")

rm -rf "$TMP_PARAGON_DIR" "$TMP_BRAND_DIR"
rm -rf "$BRAND_STATIC_DIR"/*
rm -rf "$PARAGON_OUTPUT_DIR"/*
mkdir -p "$BRAND_STATIC_DIR" "$PARAGON_OUTPUT_DIR" "$TMP_PARAGON_DIR" "$TMP_BRAND_DIR"

resolve_brand_repository

npx --prefix "$PARAGON_BUILDER_DIR" paragon build-tokens \
    --source "$TMP_BRAND_DIR/paragon/tokens" \
    --build-dir "$TMP_PARAGON_DIR" \
    "$@"

find "$TMP_PARAGON_DIR" -type f -name 'index.css' | while read -r index; do
    if [ -f "$index" ]; then
        build_css_bundle "$index"
    fi
done

cp -a "$TMP_PARAGON_DIR/." "$PARAGON_OUTPUT_DIR/"

if [ -d "$TMP_BRAND_DIR/paragon/fonts" ]; then
    cp -a "$TMP_BRAND_DIR/paragon/fonts" "$PARAGON_OUTPUT_DIR/fonts"
fi

copy_brand_asset_if_relative "$BRAND_LOGO"
copy_brand_asset_if_relative "$BRAND_LOGO_TRADEMARK"
copy_brand_asset_if_relative "$BRAND_LOGO_WHITE"
copy_brand_asset_if_relative "$BRAND_FAVICON"

chmod -R a+rw "$BRAND_STATIC_DIR" "$PARAGON_OUTPUT_DIR"
