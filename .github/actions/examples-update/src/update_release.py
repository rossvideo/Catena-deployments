import re
import json
import os


def update_chart_yaml(chart_yaml_path, new_app_version):
    """Update Chart.yaml appVersion and bump chart version patch if appVersion changed.

    Returns the current or bumped chart version.
    """
    with open(chart_yaml_path) as f:
        chart_yaml = f.read()

    current_app_version = re.search(
        r'^appVersion: "(.*)"$', chart_yaml, flags=re.MULTILINE
    ).group(1)
    current_chart_version = re.search(
        r"^version: (.*)$", chart_yaml, flags=re.MULTILINE
    ).group(1)
    print(f"Current appVersion in {chart_yaml_path}: {current_app_version}")

    if current_app_version == new_app_version:
        print(
            f"appVersion in {chart_yaml_path} matches {new_app_version}, no update needed"
        )
        return current_chart_version

    print(
        f"appVersion changed {current_app_version} -> {new_app_version}, bumping chart patch version"
    )

    chart_version_parts = current_chart_version.split(".")
    chart_version_parts[-1] = str(int(chart_version_parts[-1]) + 1)
    new_chart_version = ".".join(chart_version_parts)

    chart_yaml = re.sub(
        r"^version: .*$",
        f"version: {new_chart_version}",
        chart_yaml,
        flags=re.MULTILINE,
    )
    chart_yaml = re.sub(
        r"^appVersion: .*$",
        f'appVersion: "{new_app_version}"',
        chart_yaml,
        flags=re.MULTILINE,
    )

    with open(chart_yaml_path, "w") as f:
        f.write(chart_yaml)
    print(
        f"Updated {chart_yaml_path}: appVersion={new_app_version}, version={new_chart_version}"
    )
    return new_chart_version


def process_examples_list(examples_list_json):
    """Parse a flat JSON array of 'connection/example-name' strings into a grouped dict.

    Strips the '-connection' suffix from example names if present.
    Returns: {connection: [example_name, ...]} with sorted lists.
    """
    examples = json.loads(examples_list_json)
    out = {}
    for entry in examples:
        conn, ex_name = entry.split("/", 1)
        if ex_name.endswith(f"-{conn}"):
            ex_name = ex_name[: -(len(conn) + 1)]
        out.setdefault(conn, []).append(ex_name)
    for conn in out:
        out[conn] = sorted(out[conn])
    return out


def write_examples_json(examples_json_path, examples_dict, app_version, chart_version):
    """Write examples.json with version metadata and grouped examples."""
    out = {"version": app_version, "chartVersion": chart_version}
    out.update(examples_dict)
    with open(examples_json_path, "w") as f:
        json.dump(out, f, indent=2, sort_keys=True)
    print(
        f"Written {examples_json_path}: version={app_version}, chartVersion={chart_version}"
    )


GO_KEY = "go"


def _replace_between_markers(text, name, lines):
    start_marker = f"<!-- {name}_START -->"
    end_marker = f"<!-- {name}_END -->"
    start_idx = text.index(start_marker) + len(start_marker)
    end_idx = text.index(end_marker)
    body = "\n" + "\n".join(lines) + "\n" if lines else "\n"
    return text[:start_idx] + body + text[end_idx:]


def update_readme(readme_path, examples_dict):
    """Rewrite the README example lists.

    C++ examples go between <!-- EXAMPLES_START/END --> grouped under a heading per
    transport; Go examples go between <!-- GO_EXAMPLES_START/END --> as a flat list,
    since one Go image serves every transport.
    """
    cpp_lines = []
    for conn in sorted(k for k in examples_dict if k != GO_KEY):
        cpp_lines.append(f"### {conn}")
        cpp_lines.extend(f"- {ex}" for ex in sorted(examples_dict[conn]))
    go_lines = [f"- {ex}" for ex in sorted(examples_dict.get(GO_KEY, []))]

    with open(readme_path) as f:
        readme = f.read()

    readme = _replace_between_markers(readme, "EXAMPLES", cpp_lines)
    readme = _replace_between_markers(readme, "GO_EXAMPLES", go_lines)

    with open(readme_path, "w") as f:
        f.write(readme)
    print(f"Updated {readme_path} with new examples list")


if __name__ == "__main__":
    examples_json_path = os.environ["EXAMPLES_JSON"]
    chart_yaml_path = os.environ["CHART_YAML"]
    readme_path = os.environ["README_PATH"]
    app_version = os.environ["NEW_APP_VERSION"]
    examples_list = os.environ["EXAMPLES_LIST"]

    chart_version = update_chart_yaml(chart_yaml_path, app_version)
    examples_dict = process_examples_list(examples_list)
    write_examples_json(examples_json_path, examples_dict, app_version, chart_version)
    update_readme(readme_path, examples_dict)
