"""PyCompatLayer - Compatibility layer for Python.

It make all versions of Python behaving as the latest version of Python 3.
It will allow to add compatibility with all versions of Python without effort.
It is still under development, not all functions are supported.
"""

import sys

__version__ = "0.0.10-1"
__author__ = "ale5000"
__copyright__ = "Copyright (C) 2016, ale5000"
__license__ = "LGPLv3+"


def fix_base(fix_environ):
    """Activate the base compatibility."""
    def _fix_android_environ():
        import os

        if "LD_LIBRARY_PATH" not in os.environ:
            os.environ["LD_LIBRARY_PATH"] = "."

        lib64_path = ""
        lib32_path = os.pathsep + "/system/lib"
        if os.path.exists("/system/lib64"):
            lib64_path = os.pathsep + "/system/lib64"

        os.environ["LD_LIBRARY_PATH"] += lib64_path + lib32_path

    def _fix_android_plat():
        from distutils.spawn import find_executable
        if find_executable("dalvikvm") is not None:
            sys.platform = "linux-android"

    if sys.platform == "linux4" or sys.platform.startswith("linux-armv"):
        _fix_android_plat()

    if sys.platform.startswith("linux") and "-" not in sys.platform:
        sys.platform = "linux"

    if fix_environ and sys.platform == "linux-android":
        _fix_android_environ()


def fix_builtins(override_debug=False):
    """Activate the builtins compatibility."""
    override_dict = {}
    orig_print = None
    used_print = None

    if(__builtins__.__class__ is dict):
        builtins_dict = __builtins__
    else:
        try:
            import builtins
        except ImportError:
            import __builtin__ as builtins
        builtins_dict = builtins.__dict__

    def _deprecated(*args, **kwargs):
        """Report the fact that the called function is deprecated."""
        import traceback
        raise DeprecationWarning("the called function is deprecated => " +
                                 traceback.extract_stack(None, 2)[0][3])

    def _print_wrapper(*args, **kwargs):
        flush = kwargs.get("flush", False)
        if "flush" in kwargs:
            del kwargs["flush"]
        orig_print(*args, **kwargs)
        if flush:
            kwargs.get("file", sys.stdout).flush()

    def _print_full(*args, **kwargs):
        opt = {"sep": " ", "end": "\n", "file": sys.stdout, "flush": False}
        for key in kwargs:
            if(key in opt):
                opt[key] = kwargs[key]
            else:
                raise TypeError("'"+key+"' is an invalid keyword argument "
                                "for this function")
        opt["file"].write(opt["sep"].join(str(val) for val in args)+opt["end"])
        if opt["flush"]:
            opt["file"].flush()

    def _sorted(list):
        list.sort()
        return list

    if builtins_dict.get(__name__, False):
        raise RuntimeError(__name__+" already loaded")

    # Function 'input'
    if builtins_dict.get("raw_input") is not None:
        override_dict["input"] = builtins_dict.get("raw_input")
    override_dict["raw_input"] = _deprecated
    # Function 'print' (also aliased as print_)
    if sys.version_info >= (3, 3):
        used_print = builtins_dict.get("print")
    else:
        orig_print = builtins_dict.get("print")
        if orig_print is not None:
            used_print = _print_wrapper
        else:
            used_print = _print_full
        override_dict["print"] = used_print
    override_dict["print_"] = used_print
    # Function 'sorted'
    if builtins_dict.get("sorted") is None:
        override_dict["sorted"] = _sorted

    override_dict[__name__] = True
    builtins_dict.update(override_dict)
    del override_dict


def fix_subprocess(override_debug=False, override_exception=False):
    """Activate the subprocess compatibility."""
    import subprocess

    class ExtendedCalledProcessError(subprocess.CalledProcessError):
        """This exception is raised when a process run by check_call() or check_output() returns a non-zero exit status."""
        def __init__(self, returncode, cmd, output=None, stderr=None):
            try:
                super(self.__class__, self).__init__(returncode=returncode, cmd=cmd, output=output, stderr=stderr)
            except TypeError:
                try:
                    super(self.__class__, self).__init__(returncode=returncode, cmd=cmd, output=output)
                except TypeError:
                    super(self.__class__, self).__init__(returncode=returncode, cmd=cmd)
                    self.output = output
                self.stdout = output
                self.stderr = stderr

    def _check_output(*args, **kwargs):
        if "stdout" in kwargs:
            raise ValueError("stdout argument not allowed, "
                             "it will be overridden.")
        process = subprocess.Popen(stdout=subprocess.PIPE, *args, **kwargs)
        stdout_data, __ = process.communicate()
        ret_code = process.poll()
        if ret_code is None:
            raise RuntimeWarning("The process is not yet terminated.")
        if ret_code:
            cmd = kwargs.get("args")
            if cmd is None:
                cmd = args[0]
            raise ExtendedCalledProcessError(returncode=ret_code, cmd=cmd, output=stdout_data)
        return stdout_data

    try:
        subprocess.check_output
    except AttributeError:
        subprocess.check_output = _check_output


def fix_all(override_debug=False, override_all=False):
    """Activate the full compatibility."""
    fix_base(True)
    fix_builtins(override_debug)
    fix_subprocess(override_debug, override_all)
