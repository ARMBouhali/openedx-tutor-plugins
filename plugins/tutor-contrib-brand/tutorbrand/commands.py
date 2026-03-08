import click

@click.command(context_settings=dict(ignore_unknown_options=True, allow_extra_args=True))
@click.pass_context
def brand_build(ctx: click.Context) -> list[tuple[str, str]]:
    """Build branded Paragon outputs and publish logo assets."""
    return [("brand-builder", " ".join(ctx.args))]
