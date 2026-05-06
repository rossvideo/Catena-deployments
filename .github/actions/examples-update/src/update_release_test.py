import json
import os
import unittest

import update_release


# to run the tests, just run this file
class TestUpdateRelease(unittest.TestCase):
    def setUp(self):
        # make an output directory for test artifacts
        self.output_dir = "test_output"
        os.makedirs(self.output_dir, exist_ok=True)
        # make a .gitignore file to ignore test artifacts
        with open(os.path.join(self.output_dir, ".gitignore"), "w") as f:
            f.write("*\n")

    @property
    def chart_yaml_path(self):
        return os.path.join(self.output_dir, "test_chart.yaml")

    def make_chart_yaml(self):
        with open(self.chart_yaml_path, "w") as f:
            f.write("""apiVersion: v2
name: test-chart
description: A Helm chart for testing
type: application
version: 1.2.3
appVersion: "1.2.3"
""")

    @property
    def readme_path(self):
        return os.path.join(self.output_dir, "README.md")

    def make_readme(self):
        with open(self.readme_path, "w") as f:
            f.write("""# Test README
## List of examples
<!-- EXAMPLES_START -->
### REST
- example-1
- example-2
### gRPC
- example-1
<!-- EXAMPLES_END -->

## Next Section
""")

    def test_update_chart_yaml(self):
        # create a temporary chart.yaml file
        self.make_chart_yaml()
        # update the chart.yaml with a new version
        new_version = "2.0.0"
        expected_chart_version = "1.2.4"
        new_chart_version = update_release.update_chart_yaml(
            self.chart_yaml_path, new_version
        )
        # assert the chart version is reved
        self.assertEqual(new_chart_version, expected_chart_version)
        # read the updated chart.yaml
        with open(self.chart_yaml_path) as f:
            updated_chart_yaml = f.read()
        # check that the version and appVersion were updated correctly
        self.assertIn(f"version: {expected_chart_version}", updated_chart_yaml)
        self.assertIn(f'appVersion: "{new_version}"', updated_chart_yaml)

    def test_update_chart_yaml_same_version(self):
        # create a temporary chart.yaml file
        self.make_chart_yaml()
        # update the chart.yaml with the same version
        new_version = "1.2.3"
        expected_chart_version = "1.2.3"
        new_chart_version = update_release.update_chart_yaml(
            self.chart_yaml_path, new_version
        )
        # assert the chart version is unchanged
        self.assertEqual(new_chart_version, expected_chart_version)
        # read the updated chart.yaml
        with open(self.chart_yaml_path) as f:
            updated_chart_yaml = f.read()
        # check that the version and appVersion were unchanged
        self.assertIn(f"version: {expected_chart_version}", updated_chart_yaml)
        self.assertIn(f'appVersion: "{new_version}"', updated_chart_yaml)

    def test_process_examples_list(self):
        examples_list_json = [
            "REST/example-1",
            "REST/example-2",
            "gRPC/example-1",
            "gRPC/example-2",
            "gRPC/example-3",
        ]
        expected_output = {
            "REST": ["example-1", "example-2"],
            "gRPC": ["example-1", "example-2", "example-3"],
        }
        output = update_release.process_examples_list(json.dumps(examples_list_json))
        self.assertEqual(output, expected_output)

    def test_process_examples_list_strips_suffix(self):
        # examples named 'foo-REST' or 'bar-gRPC' should have the suffix stripped
        examples_list_json = [
            "REST/example-1-REST",
            "gRPC/example-1-gRPC",
            "gRPC/example-2-gRPC",
        ]
        expected_output = {
            "REST": ["example-1"],
            "gRPC": ["example-1", "example-2"],
        }
        output = update_release.process_examples_list(json.dumps(examples_list_json))
        self.assertEqual(output, expected_output)

    @property
    def examples_json_path(self):
        return os.path.join(self.output_dir, "examples.json")

    def test_write_examples_json(self):
        examples_dict = {
            "REST": ["example-1", "example-2"],
            "gRPC": ["example-1"],
        }
        update_release.write_examples_json(
            self.examples_json_path, examples_dict, "2.0.0", "1.2.4"
        )
        with open(self.examples_json_path) as f:
            written = json.load(f)
        self.assertEqual(written["version"], "2.0.0")
        self.assertEqual(written["chartVersion"], "1.2.4")
        self.assertEqual(written["REST"], ["example-1", "example-2"])
        self.assertEqual(written["gRPC"], ["example-1"])

    def test_update_readme(self):
        new_examples_dict = {
            "REST": ["example-1", "example-3"],
            "gRPC": ["example-1", "example-2"],
        }
        self.make_readme()
        update_release.update_readme(self.readme_path, new_examples_dict)
        with open(self.readme_path) as f:
            updated = f.read()
        # check the section was replaced
        self.assertIn("### REST", updated)
        self.assertIn("- example-1", updated)
        self.assertIn("- example-3", updated)
        self.assertIn("### gRPC", updated)
        self.assertIn("- example-2", updated)
        # old content should be gone
        self.assertNotIn("- example-2\n### gRPC", updated)
        # markers must still be present
        self.assertIn("<!-- EXAMPLES_START -->", updated)
        self.assertIn("<!-- EXAMPLES_END -->", updated)
        # content after the end marker should be preserved
        self.assertIn("## Next Section", updated)


if __name__ == "__main__":
    unittest.main()
