"""
Unit tests for the src.io.input module.
"""
import unittest
import os
import sys
import trimesh

# Add project root to sys.path to allow direct execution of tests
# and to import modules from src
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

from src.io.input import load_mesh

class TestInputModule(unittest.TestCase):
    """
    Test cases for the load_mesh function in src.io.input.
    """

    @classmethod
    def setUpClass(cls):
        """
        Set up for all tests in the class.
        Create the dummy cube.obj if it doesn't exist (it should, but good practice).
        """
        cls.valid_obj_path = "assets/cube.obj"
        cls.non_existent_obj_path = "assets/nonexistent.obj"
        cls.unsupported_file_path = "assets/test.txt"

        # Ensure the valid OBJ file exists for tests
        if not os.path.exists(cls.valid_obj_path):
            # This is the content from the task description
            cube_obj_content = """
# Simple Cube
v 1.0 1.0 -1.0
v 1.0 -1.0 -1.0
v 1.0 1.0 1.0
v 1.0 -1.0 1.0
v -1.0 1.0 -1.0
v -1.0 -1.0 -1.0
v -1.0 1.0 1.0
v -1.0 -1.0 1.0

f 1 2 4 3
f 5 6 8 7
f 1 5 7 3
f 2 6 8 4
f 1 2 6 5
f 3 4 8 7
"""
            os.makedirs(os.path.dirname(cls.valid_obj_path), exist_ok=True)
            with open(cls.valid_obj_path, "w") as f:
                f.write(cube_obj_content)

    def setUp(self):
        """
        Set up for each test method.
        Create dummy files needed for specific tests.
        """
        # Create an empty dummy file for the unsupported extension test
        with open(self.unsupported_file_path, "w") as f:
            f.write("This is a test file.")

    def tearDown(self):
        """
        Clean up after each test method.
        Remove dummy files created during tests.
        """
        if os.path.exists(self.unsupported_file_path):
            os.remove(self.unsupported_file_path)

    def test_load_valid_obj(self):
        """
        Test loading a valid OBJ file.
        """
        print(f"Testing load_mesh with: {self.valid_obj_path}")
        mesh = load_mesh(self.valid_obj_path)
        self.assertIsNotNone(mesh, "load_mesh should return an object for a valid OBJ file.")
        self.assertIsInstance(mesh, trimesh.Trimesh, "Loaded object should be a Trimesh instance.")
        print("test_load_valid_obj PASSED")

    def test_load_nonexistent_file(self):
        """
        Test loading a non-existent file.
        """
        print(f"Testing load_mesh with non-existent file: {self.non_existent_obj_path}")
        mesh = load_mesh(self.non_existent_obj_path)
        self.assertIsNone(mesh, "load_mesh should return None for a non-existent file.")
        print("test_load_nonexistent_file PASSED")

    def test_load_unsupported_extension(self):
        """
        Test loading a file with an unsupported extension (e.g., .txt).
        """
        print(f"Testing load_mesh with unsupported file: {self.unsupported_file_path}")
        mesh = load_mesh(self.unsupported_file_path)
        self.assertIsNone(mesh, "load_mesh should return None for an unsupported file extension.")
        print("test_load_unsupported_extension PASSED")

if __name__ == '__main__':
    print("Running input tests...")
    unittest.main(verbosity=2)
