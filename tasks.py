import tomlkit
from invoke import task


@task
def update_pyproject(
    c,
    plone_version="6.1.1",
    plone_distribution="plone.volto",
    db_storage="direct",
    plone_addons=None,
):
    print("Updating pyproject.toml.")
    plone_addons = plone_addons and plone_addons.split(",") or []
    with open("pyproject.toml") as f:
        doc = tomlkit.parse(f.read())

    # add dependencies:
    dependencies = []
    dependencies.append("pyruvate")
    dependencies.append(plone_distribution)
    if db_storage == "zeo":
        dependencies.append("ZEO")
    if db_storage == "relstorage":
        dependencies.extend(
            [
                "relstorage",
                "psycopg2",
            ]
        )

    # always add required addons:
    plone_addons.extend(
        [
            "plone.app.caching",
            "plone.app.upgrade",
        ]
    )
    dependencies.extend([addon for addon in plone_addons])

    for dep in dependencies:
        if dep in doc["project"]["dependencies"]:
            continue
        doc["project"]["dependencies"].append(dep)

    # add constraint dependencies:
    constraint_dependencies = [f"Products.CMFPlone=={plone_version}"]
    for dep in constraint_dependencies:
        if dep in doc["tool"]["uv"]["constraint-dependencies"]:
            continue
        doc["tool"]["uv"]["constraint-dependencies"].append(dep)

    with open("pyproject.toml", "w") as f:
        f.write(tomlkit.dumps(doc))
