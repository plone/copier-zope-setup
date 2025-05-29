import tomlkit
from invoke import task


@task
def update_pyproject(c, plone_version="6.1.1", plone_distribution="plone.volto"):
    print("Updating pyproject.toml.")
    print(plone_distribution)
    with open("pyproject.toml") as f:
        doc = tomlkit.parse(f.read())

    # add dependencies:
    dependencies = ["pyruvate"]
    dependencies.append(plone_distribution)
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
