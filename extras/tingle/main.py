#!/usr/bin/env python
"""Tingle - File patcher for Android."""

import sys
import os
import subprocess
import tempfile
import shutil

__app__ = "Tingle"
__author__ = "ale5000, moosd"

DEPS_PATH = {}
DEBUG_PROCESS = False
UNLOCKED_ADB = True


def init():
    global SCRIPT_DIR, TMP_DIR, PREVIOUS_DIR, DUMB_MODE
    SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

    sys.path.append(os.path.join(SCRIPT_DIR, "libs"))
    import atexit
    import pycompatlayer

    if sys.platform == "win32":
        os.system("TITLE "+__app__)

    # Activate Python compatibility layer
    pycompatlayer.fix_all()

    # Add tools folder to search path (used from subprocess)
    os.environ["PATH"] = SCRIPT_DIR+os.sep+"tools" + os.pathsep + os.environ.get("PATH", "")

    # Set constants (they won't be changed again)
    TMP_DIR = None
    PREVIOUS_DIR = os.getcwd()
    DUMB_MODE = False
    if os.environ.get("TERM") == "dumb":
        DUMB_MODE = True

    # Register exit handler
    atexit.register(on_exit)


def on_exit():
    # Return to the previous working directory
    os.chdir(PREVIOUS_DIR)
    # Clean up
    if TMP_DIR is not None:
        shutil.rmtree(TMP_DIR+"/")
    if sys.platform == "win32" and not DUMB_MODE:
        import msvcrt
        msvcrt.getch()  # Wait a keypress before exit (useful when the script is running from a double click)


def exit(error_code):
    if error_code != 0:
        print_(os.linesep+"ERROR CODE:", error_code)
    sys.exit(error_code)


def handle_dependencies(deps_path, mode):
    from distutils.spawn import find_executable

    errors = ""
    if sys.platform == "linux-android":
        deps = ["dalvikvm", "busybox", "zip"]
    else:
        deps = ["java", "7za"]

    if mode == 1:
        deps += ["adb"]

    for dep in deps:
        path = find_executable(dep+"-"+sys.platform)
        if path is None:
            path = find_executable(dep)

        if path is None:
            errors += os.linesep + "ERROR: Missing executable => "+dep
        else:
            deps_path[dep] = path

    if errors:
        print_(errors)
        exit(65)


def remove_ext(filename):
    return filename.rsplit(".", 1)[0]


def debug(msg):
    if msg:
        print_("      DEBUG:", msg)


def warning(msg, first_line=True):
    if first_line:
        print_("      WARNING:", msg)
    else:
        print_("              ", msg)


def get_OS():
    import platform
    return platform.system()+" "+platform.release()


def parse_7za_version(output):
    output = output[:output.index("Copyright")].strip(" :")
    return output[output.rindex(" ")+1:]


def display_info():
    print_(os.linesep+"-----------------------")
    print_("Name: "+__app__)
    print_("Author: "+__author__+os.linesep)

    print_("Installed dependencies:")
    print_("- 7za "+parse_7za_version(subprocess.check_output(["7za", "i"]).decode("utf-8")))
    print_("-----------------------"+os.linesep)


def input_byte(msg):
    print_(msg, end="", flush=True)
    if DUMB_MODE:
        print_()
        return ""
    try:
        val = sys.stdin.readline()
        # KeyboardInterrupt leave a "", instead an empty value leave a "\n"
        if val == "":
            import time
            time.sleep(0.02)  # Give some time for the exception to being caught
    except KeyboardInterrupt:
        raise EOFError
    else:
        return val.strip()[:1]


def user_question(msg, max_val, default_val=1, show_question=True):
    if show_question:
        print_(msg)
    try:
        val = input_byte("> ")
    except EOFError:
        print_(os.linesep+os.linesep+"Killed by the user, now exiting ;)")
        sys.exit(130)

    if(val == ""):
        print_("Used default value.")
        return default_val
    elif(val == "i"):
        display_info()
        return user_question(msg, max_val, default_val, True)

    try:
        val = int(val)
        if 0 < val <= max_val:
            return val
    except ValueError:
        pass

    print_("Invalid value, try again...")
    return user_question(msg, max_val, default_val, False)


def select_device():
    # Start adb server before using it otherwise we get an unintended output inside other commands
    subprocess.check_output([DEPS_PATH["adb"], "start-server"])
    devices = subprocess.check_output([DEPS_PATH["adb"], "devices"]).decode("utf-8")
    if devices.count(os.linesep) <= 2:
        print_(os.linesep+"ERROR: No device detected! Please connect your device first.")
        exit(0)

    devices = devices.split(os.linesep)[1:-2]
    devices = [a.split("\t")[0] for a in devices]

    if len(devices) > 1:
        print_()
        question = "Enter id of device to target:"+os.linesep+os.linesep+"    "+(os.linesep+"    ").join([str(i)+" - "+a for i, a in zip(range(1, len(devices)+1), devices)])+os.linesep
        id = user_question(question, len(devices))
        chosen_one = devices[id-1]
    else:
        chosen_one = devices[0]
    return chosen_one


def root_adbd(chosen_device):
    print_(" *** Rooting adbd...")
    root_output = subprocess.check_output([DEPS_PATH["adb"], "-s", chosen_device, "root"]).decode("utf-8")

    if "root access is disabled" in root_output:
        print_(os.linesep+"ERROR: You do NOT have root or root access is disabled.")
        print_(os.linesep+"Enable it in Settings -> Developer options -> Root access -> Apps and ADB.")
        exit(80)

    debug(root_output.rstrip())

    if "adbd is already running as root" in root_output:
        return

    if "adbd cannot run as root in production builds" in root_output:
        global UNLOCKED_ADB
        UNLOCKED_ADB = False
        return

    subprocess.check_call([DEPS_PATH["adb"], "-s", chosen_device, "wait-for-device"])


def enable_device_writing(chosen_device):
    root_adbd(chosen_device)
    print_(" *** Unlocked ADB:", UNLOCKED_ADB)

    print_(" *** Remounting /system...")
    if(UNLOCKED_ADB):
        remount_check = subprocess.check_output([DEPS_PATH["adb"], "-s", chosen_device, "remount", "/system"]).decode("utf-8")
    else:
        remount_check = subprocess.check_output([DEPS_PATH["adb"], "-s", chosen_device, "shell", "su -c 'mount -o remount,rw /system && mount' | grep /system"]).decode("utf-8")  # Untested
        debug(remount_check.rstrip())
        if "su: not found" in remount_check:
            print_(os.linesep+"ERROR: The device is NOT rooted.")
            exit(81)
        if "rw," not in remount_check:
            print_(os.linesep+"ERROR: Alternative remount failed.")
            exit(81)
    debug(remount_check.rstrip())
    if("remount failed" in remount_check) and ("Success" not in remount_check):  # Do NOT stop with "remount failed: Success"
        print_(os.linesep+"ERROR: Remount failed.")
        exit(81)


def safe_copy(orig, dest):
    shutil.copyfile(orig, dest)
    try:
        shutil.copystat(orig, dest)  # It may fail on Android
    except OSError:
        warning("shutil.copystat has failed.")


def safe_move(orig, dest):
    if not os.path.exists(orig) or os.path.exists(dest.rstrip("/")):
        print_(os.linesep+"ERROR: Safe move fail.")  # ToDO: Notify error better
        exit(85)
    shutil.move(orig, dest)


def safe_file_delete(file_path):
    if os.path.exists(file_path):
        os.remove(file_path)


def clean_dalvik_cache(file):
    safe_file_delete("/data/dalvik-cache/"+file[1:].replace("/", "@")+"@classes.dex")


def brew_input_file(mode, chosen_one):
    if mode == 1:
        # Pull framework somewhere temporary
        print_(" *** Pulling framework from device...")
        output = subprocess.check_output([DEPS_PATH["adb"], "-s", chosen_one, "pull", "/system/framework/framework.jar", "."], stderr=subprocess.STDOUT)
        debug(output.decode("utf-8").rstrip())
    elif mode == 2:
        safe_copy(SCRIPT_DIR+"/input/framework.jar", TMP_DIR+"/framework.jar")
    else:
        safe_copy("/system/framework/framework.jar", TMP_DIR+"/framework.jar")


def decompress(file, out_dir):
    debug("Decompressing "+file)
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)
    if sys.platform == "linux-android":
        decomp_cmd = [DEPS_PATH["busybox"], "unzip", "-oq", "-d", out_dir]
    else:
        decomp_cmd = [DEPS_PATH["7za"], "x", "-y", "-bd", "-tzip", "-o"+out_dir]
    decomp_cmd.extend([file, "*.dex"])

    try:
        subprocess.check_output(decomp_cmd)
    except subprocess.CalledProcessError as e:
        print_(os.linesep+e.output.decode("utf-8").strip())
        print_(os.linesep+"Return code: "+str(e.returncode))
        exit(87)
    return True


def compress(in_dir, file):
    debug("Compressing "+file)
    if sys.platform == "linux-android":
        comp_cmd = ["zip", "-qrj9X", file, in_dir, "-i", "*.dex"]
    else:
        comp_cmd = [DEPS_PATH["7za"], "a", "-y", "-bd", "-tzip", file, in_dir+"*.dex"]

    try:
        subprocess.check_output(comp_cmd)
    except subprocess.CalledProcessError as e:
        print_(os.linesep+e.output.decode("utf-8").strip())
        print_(os.linesep+"Cmd: "+str(e.cmd))
        print_(os.linesep+"Return code: "+str(e.returncode))
        exit(88)
    return True


def disassemble(file, out_dir):
    debug("Disassembling "+file)
    if sys.platform == "linux-android":
        disass_cmd = [DEPS_PATH["dalvikvm"], "-Xmx128m", "-cp", SCRIPT_DIR+"/tools/baksmali-dvk.jar", "org.jf.baksmali.main"]
    else:
        disass_cmd = [DEPS_PATH["java"], "-jar", SCRIPT_DIR+"/tools/baksmali.jar"]
    disass_cmd.extend(["-lsx", "-o"+out_dir, file])

    subprocess.check_call(disass_cmd)
    if sys.platform == "linux-android":
        clean_dalvik_cache(SCRIPT_DIR+"/tools/baksmali-dvk.jar")
    return True


def assemble(in_dir, file, hide_output=False):
    debug("Assembling "+file)
    if sys.platform == "linux-android":
        ass_cmd = [DEPS_PATH["dalvikvm"], "-Xmx166m", "-cp", SCRIPT_DIR+"/tools/smali-dvk.jar", "org.jf.smali.main", "-j1"]
    else:
        ass_cmd = [DEPS_PATH["java"], "-jar", SCRIPT_DIR+"/tools/smali.jar"]
    ass_cmd.extend(["-o"+file, in_dir])

    if hide_output:
        return subprocess.check_output(ass_cmd, stderr=subprocess.STDOUT)
    subprocess.check_call(ass_cmd)
    if sys.platform == "linux-android":
        clean_dalvik_cache(SCRIPT_DIR+"/tools/smali-dvk.jar")
    return True


def find_smali(smali_to_search, dir):
    dir_list = tuple(sorted(os.listdir(dir)))

    if len(dir_list) == 0:
        print_(os.linesep+"ERROR: No dex file(s) found, probably the ROM is odexed.")
        exit(86)

    for filename in dir_list:
        out_dir = "./smali-"+remove_ext(filename)+"/"
        disassemble(dir+filename, out_dir)
        if os.path.exists(out_dir+smali_to_search):
            return (out_dir, filename, dir_list[-1])
    return (None, None, None)


def move_methods_workaround(dex_filename, dex_filename_last, in_dir, out_dir):
    if(dex_filename == dex_filename_last):
        print_(os.linesep+"ERROR")  # ToDO: Notify error better
        exit(84)
    print_(" *** Moving methods...")
    warning("Experimental code.")
    smali_dir = "./smali-"+remove_ext(dex_filename)+"/"
    smali_dir_last = "./smali-"+remove_ext(dex_filename_last)+"/"
    disassemble(in_dir+dex_filename_last, smali_dir_last)
    safe_move(smali_dir+"android/bluetooth/", smali_dir_last+"android/bluetooth/")
    print_(" *** Reassembling classes...")
    assemble(smali_dir, out_dir+dex_filename)
    assemble(smali_dir_last, out_dir+dex_filename_last)
    if sys.platform == "win32":
        subprocess.check_call(["attrib", "-a", out_dir+dex_filename])
        subprocess.check_call(["attrib", "-a", out_dir+dex_filename_last])


init()

question = "MENU"+os.linesep+os.linesep+"    1 - Patch file from a device (adb)"+os.linesep+"    2 - Patch file from the input folder"+os.linesep
mode = user_question(question, 3, 2)

handle_dependencies(DEPS_PATH, mode)

chosen_one = None
if mode == 1:
    chosen_one = select_device()
    if DEBUG_PROCESS:
        print_(" *** NOTE: Running in debug mode, WILL NOT ACTUALLY PATCH AND PUSH TO DEVICE")

print_(os.linesep+" *** OS:", get_OS(), "("+sys.platform+")")
print_(" *** Mode:", mode)

TMP_DIR = tempfile.mkdtemp("", __app__+"-")
os.chdir(TMP_DIR)
print_(" *** Working dir: %s" % TMP_DIR)

if mode == 1:
    print_(" *** Selected device:", chosen_one)

if DUMB_MODE:
    exit(0)  # ToDO: Implement full test in dumb mode

brew_input_file(mode, chosen_one)

print_(" *** Decompressing framework...")
decompress("framework.jar", "framework/")

# Disassemble it
print_(" *** Disassembling classes...")
smali_to_search = "android/content/pm/PackageParser.smali"
smali_folder, dex_filename, dex_filename_last = find_smali(smali_to_search, "framework/")

# Check the existence of the file to patch
if smali_folder is None:
    print_(os.linesep+"ERROR: The file to patch cannot be found, please report the problem.")
    exit(82)
to_patch = smali_folder+smali_to_search

# Do the injection
print_(" *** Patching...")
f = open(to_patch, "r")
old_contents = f.readlines()
f.close()

f = open(SCRIPT_DIR+"/patches/fillinsig.smali", "r")
fillinsig = f.readlines()
f.close()

# Add fillinsig method
i = 0
contents = []
already_patched = False
in_function = False
right_line = False
start_of_line = None
done_patching = False
stored_register = "v11"
partially_patched = False

while i < len(old_contents):
    if ";->fillinsig" in old_contents[i]:
        already_patched = True
    if ".method public static fillinsig" in old_contents[i]:
        partially_patched = True
    if ".method public static generatePackageInfo(Landroid/content/pm/PackageParser$Package;[IIJJLjava/util/Set;Landroid/content/pm/PackageUserState;I)Landroid/content/pm/PackageInfo;" in old_contents[i]:
        print_(" *** Detected: Android 7.x / Android 6.0.x / CyanogenMod 13-14")
        in_function = True
    if ".method public static generatePackageInfo(Landroid/content/pm/PackageParser$Package;[IIJJLandroid/util/ArraySet;Landroid/content/pm/PackageUserState;I)Landroid/content/pm/PackageInfo;" in old_contents[i]:
        print_(" *** Detected: Android 5.x / CyanogenMod 12")
        in_function = True
    if ".method public static generatePackageInfo(Landroid/content/pm/PackageParser$Package;[IIJJLjava/util/HashSet;Landroid/content/pm/PackageUserState;I)Landroid/content/pm/PackageInfo;" in old_contents[i]:
        print_(" *** Detected: Android 4.4.x / CyanogenMod 10-11")
        in_function = True
    if ".method public static generatePackageInfo(Landroid/content/pm/PackageParser$Package;[IIJJ)Landroid/content/pm/PackageInfo;" in old_contents[i]:
        print_(" *** Detected: CyanogenMod 7-9 - UNTESTED")
        in_function = True
    if ".method public static generatePackageInfo(Landroid/content/pm/PackageParser$Package;[II)Landroid/content/pm/PackageInfo;" in old_contents[i]:
        print_(" *** Detected: CyanogenMod 6 - UNTESTED")
        in_function = True
    if ".method public static generatePackageInfo(Landroid/content/pm/PackageParser$Package;[IIJJLjava/util/HashSet;ZII)Landroid/content/pm/PackageInfo;" in old_contents[i]:
        print_(" *** Detected: Alien Dalvik (Sailfish OS)")
        in_function = True
    if ".end method" in old_contents[i]:
        in_function = False
    if in_function and ".line" in old_contents[i]:
        start_of_line = i + 1
    if in_function and "arraycopy" in old_contents[i]:
        right_line = True
    if in_function and "Landroid/content/pm/PackageInfo;-><init>()V" in old_contents[i]:
        stored_register = old_contents[i].split("{")[1].split("}")[0]
    if not already_patched and in_function and right_line and not done_patching:
        contents = contents[:start_of_line]
        contents.append("move-object/from16 v0, p0\n")
        contents.append("invoke-static {%s, v0}, Landroid/content/pm/PackageParser;->fillinsig(Landroid/content/pm/PackageInfo;Landroid/content/pm/PackageParser$Package;)V\n" % stored_register)
        done_patching = True
    else:
        contents.append(old_contents[i])
    i = i + 1

if not DEBUG_PROCESS:
    if already_patched:
        print_(" *** This file has been already patched... Exiting.")
        exit(0)
    elif not done_patching:
        print_(os.linesep+"ERROR: The function to patch cannot be found, probably your version of Android is NOT supported.")
        exit(89)
    elif partially_patched:
        print_(" *** Previous failed patch attempt, not including the fillinsig method again...")
    else:
        contents.extend(fillinsig)

    f = open(to_patch, "w")
    contents = "".join(contents)
    f.write(contents)
    f.close()
print_(" *** Patching succeeded.")

# Reassemble it
print_(" *** Reassembling classes...")
os.makedirs("out/")

try:
    assemble(smali_folder, "out/"+dex_filename, True)
    if sys.platform == "win32":
        subprocess.check_call(["attrib", "-a", "out/"+dex_filename])
except subprocess.CalledProcessError as e:  # ToDO: Check e.cmd
    safe_file_delete(TMP_DIR+"/out/"+dex_filename)  # Remove incomplete file
    output = e.output.decode("utf-8")
    if e.returncode != 2 or "Unsigned short value out of range: 65536" not in output:
        print_(os.linesep+output.strip())
        print_(os.linesep+"Return code: "+str(e.returncode))
        exit(83)
    warning("The reassembling has failed (probably we have exceeded the 64K methods limit)")
    warning("but do NOT worry, we will retry.", False)
    move_methods_workaround(dex_filename, dex_filename_last, "framework/", "out/")

# Backup the original file
safe_copy(TMP_DIR+"/framework.jar", SCRIPT_DIR+"/output/framework.jar.backup")

# Put classes back in the archive
print_(" *** Recompressing framework...")
compress(os.curdir+"/out/", "framework.jar")

# Copy the patched file to the output folder
print_(" *** Copying the patched file to the output folder...")
safe_copy(TMP_DIR+"/framework.jar", SCRIPT_DIR+"/output/framework.jar")

if mode == 1:
    enable_device_writing(chosen_one)
    # Push to device
    print_(" *** Pushing changes to the device...")
    try:
        if not DEBUG_PROCESS:
            output = subprocess.check_output([DEPS_PATH["adb"], "-s", chosen_one, "push", "framework.jar", "/system/framework/framework.jar"], stderr=subprocess.STDOUT)
            debug(output.decode("utf-8").rstrip())
    except subprocess.CalledProcessError as e:
        output = e.output.decode("utf-8")
        debug(output.strip())
        if e.returncode == 1 and "No space left on device" in output:
            warning("Pushing has failed, we will retry from the recovery.")
            subprocess.check_call([DEPS_PATH["adb"], "-s", chosen_one, "reboot", "recovery"])
            subprocess.check_call([DEPS_PATH["adb"], "-s", chosen_one, "wait-for-device"])
            enable_device_writing(chosen_one)
            subprocess.check_output([DEPS_PATH["adb"], "-s", chosen_one, "push", "framework.jar", "/system/framework/framework.jar"])
        else:
            raise
    # Kill ADB server
    subprocess.check_call([DEPS_PATH["adb"], "kill-server"])

print_(" *** All done! :)")

backup_jar = os.path.join(SCRIPT_DIR, "output", "framework.jar.backup")
print_(os.linesep + "Your original file is present at "+backup_jar)
print_(os.linesep + "If your device bootloop, please run this when inside recovery:" + os.linesep + "adb push \""+backup_jar+"\" /system/framework/framework.jar")
