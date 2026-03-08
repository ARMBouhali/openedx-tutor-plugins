import logging
import os
from glob import glob
from urllib.parse import urlparse

import importlib_resources
from tutor import config as tutor_config
from tutor import hooks

from .__about__ import __version__
from .commands import brand_build

logger = logging.getLogger(__name__)


hooks.Filters.CONFIG_DEFAULTS.add_items(
    [
        ("BRAND_PLUGIN_VERSION", __version__),
        ("BRAND_REPOSITORY", "env/plugins/brand/repository"),
        ("BRAND_VERSION", "main"),
        ("BRAND_OUTPUT_PATH", "env/plugins/brand/static"),
        ("BRAND_WORKDIR", "env/plugins/brand/workdir"),
        ("BRAND_BUILDER_IMAGE", "brand-builder:latest"),
        ("BRAND_STATIC_URL_PREFIX", "static/brand/"),
        ("BRAND_LOGO", "logo.svg"),
        ("BRAND_LOGO_TRADEMARK", "logo-trademark.svg"),
        ("BRAND_LOGO_WHITE", "logo-white.svg"),
        ("BRAND_FAVICON", "favicon.ico"),
        ("PARAGON_COMPILED_THEMES_PATH", "env/plugins/paragon/compiled-themes"),
        ("PARAGON_ENABLED_THEMES", []),
        ("PARAGON_BUILDER_IMAGE", "paragon-builder:latest"),
        ("MFE_HOST_EXTRA_FILES", True),
    ]
)


def _is_url(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme in ("http", "https")


@hooks.Actions.PROJECT_ROOT_READY.add()
def create_brand_folders(project_root: str) -> None:
    config = tutor_config.load(project_root)
    repository = str(config["BRAND_REPOSITORY"])
    output_path = os.path.join(project_root, str(config["BRAND_OUTPUT_PATH"]))
    workdir_path = os.path.join(project_root, str(config["BRAND_WORKDIR"]))

    managed_paths = [
        (output_path, "Brand Output"),
        (workdir_path, "Brand Workdir"),
    ]

    if not _is_url(repository):
        managed_paths.append(
            (os.path.join(project_root, repository), "Brand Repository")
        )

    for path, label in managed_paths:
        if os.path.exists(path):
            logger.info("[brand] %s folder already exists at: %s", label, path)
        else:
            os.makedirs(path, exist_ok=True)
            logger.info("[brand] Created %s folder at: %s", label, path)


hooks.Filters.IMAGES_BUILD.add_items(
    [
        (
            "brand-builder",
            ("plugins", "brand", "build", "brand-builder"),
            "{{ BRAND_BUILDER_IMAGE }}",
            (),
        ),
    ]
)


hooks.Filters.ENV_TEMPLATE_ROOTS.add_items(
    [
        str(importlib_resources.files("tutorbrand") / "templates"),
    ]
)

hooks.Filters.ENV_TEMPLATE_TARGETS.add_items(
    [
        ("brand/build", "plugins"),
        ("brand/apps", "plugins"),
    ]
)


for path in glob(str(importlib_resources.files("tutorbrand") / "patches" / "*")):
    with open(path, encoding="utf-8") as patch_file:
        hooks.Filters.ENV_PATCHES.add_item((os.path.basename(path), patch_file.read()))


hooks.Filters.CLI_DO_COMMANDS.add_item(brand_build)
