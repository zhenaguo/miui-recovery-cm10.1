LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

commands_recovery_local_path := $(LOCAL_PATH)

LOCAL_SRC_FILES := \
	recovery_ui.cpp \
	mount.cpp \
	bootloader.cpp \
	install.cpp \
	roots.cpp \
	firmware.cpp \
	nandroid.cpp \
	verifier.cpp \
	root_device.cpp \
	reboot.cpp \
	miui_func.cpp \
	utils_func.cpp \
	recovery.cpp 



LOCAL_MODULE := recovery

#LOCAL_FORCE_STATIC_EXECUTABLE := true

RECOVERY_API_VERSION := 3
MYDEFINE_CFLAGS :=  -D_GLIBCXX_DEBUG_PEDANTIC \
                  -DFT2_BUILD_LIBRARY=1 \
                  -DDARWIN_NO_CARBON \
				  -D_MIUI_NODEBUG=1
LOCAL_CFLAGS += -DRECOVERY_API_VERSION=$(RECOVERY_API_VERSION) 
LOCAL_CFLAGS += $(MYDEFINE_CFLAGS)
#LOCAL_CFLAGS += -DRECOVERY_API_VERSION=$(RECOVERY_API_VERSION)

LOCAL_STATIC_LIBRARIES :=
LOCAL_SHARED_LIBRARIES := 

ifeq ($(TARGET_USERIMAGES_USE_EXT4), true)
LOCAL_CFLAGS += -DUSE_EXT4
LOCAL_C_INCLUDES += system/extras/ext4_utils
#LOCAL_STATIC_LIBRARIES += libext4_utils libz
LOCAL_SHARED_LIBRARIES += libext4_utils libz
endif

ifeq ($(BOARD_HAS_REMOVABLE_STORAGE), true) 
	LOCAL_CFLAGS += -DBOARD_HAS_REMOVABLE_STORAGE
endif

ifneq ($(MIUI_RECOVERY_BUILD_DEVICE),)
	LOCAL_CFLAGS += -D$(MIUI_RECOVERY_BUILD_DEVICE)
endif



# This binary is in the recovery ramdisk, which is otherwise a copy of root.
# It gets copied there in config/Makefile.  LOCAL_MODULE_TAGS suppresses
# a (redundant) copy of the binary in /system/bin for user builds.
# TODO: Build the ramdisk image in a more principled way.

LOCAL_MODULE_TAGS := eng

#LOCAL_C_INCLUDES += $(LOCAL_PATH)/include
#LOCAL_LDLIBS += $(LOCAL_PATH)/lib

LOCAL_C_INCLUDES += bionic \
		    external/libselinux/include \
		    external/stlport/stlport
LOCAL_CFLAGS += -DHAVE_SELINUX
LOCAL_STATIC_LIBRARIES += libminzip libunz libmincrypt \
			  libmkyaffs2image_static \
			  libunyaffs_static \
			  libdedupe libselinux \
			  libedify libcrecovery \
			  libcrypto_static libmiui \
			  libmd5 
			 
#LOCAL_STATIC_LIBRARIES += libminzip libunz libmtdutils libmincrypt
LOCAL_SHARED_LIBRARIES +=  libext4_utils libz libmtdutils  \
			   libflashutils libmmcutils \
			   libbmlutils  liberase_image \
			   libdump_image libflash_image \
			   libcutils libstdc++ libc libm \
			   libsparse libstlport
LOCAL_LDFLAGS := -ldl 

ifeq ($(TARGET_BOOTLOADER_BOARD_NAME), herring)
	LOCAL_CFLAGS := -DCRESPO
endif

#add static libraries
#LOCAL_STATIC_LIBRARIES += libedify libcrecovery libflashutils libmmcutils libbmlutils
#LOCAL_STATIC_LIBRARIES += libmkyaffs2image libunyaffs liberase_image libdump_image libflash_image
#LOCAL_STATIC_LIBRARIES += libmiui libcutils
#LOCAL_STATIC_LIBRARIES += libstdc++ libc libm libdedupe libcrypto_static 


LOCAL_C_INCLUDES += system/extras/ext4_utils


include $(BUILD_EXECUTABLE)

RECOVERY_LINKS := edify  flash_image dump_image mkyaffs2image unyaffs erase_image nandroid reboot  dedupe minizip 

# nc is provided by external/netcat
RECOVERY_SYMLINKS := $(addprefix $(TARGET_RECOVERY_ROOT_OUT)/sbin/,$(RECOVERY_LINKS))
$(RECOVERY_SYMLINKS): RECOVERY_BINARY := $(LOCAL_MODULE)
$(RECOVERY_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo "Symlink: $@ -> $(RECOVERY_BINARY)"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf $(RECOVERY_BINARY) $@

ALL_DEFAULT_INSTALLED_MODULES += $(RECOVERY_SYMLINKS)


ALL_DEFAULT_INSTALLED_MODULES += $(RECOVERY_SYMLINKS)
LOCAL_PREBUILT_PATH := $(LOCAL_PATH)/prebuilt_lib
BUSYBOX_PATH := $(LOCAL_PREBUILT_PATH)/busybox
# Now let's do recovery symlinks
BUSYBOX_LINKS := $(shell cat $(BUSYBOX_PATH)/busybox-minimal.links)
exclude := tune2fs mke2fs  
RECOVERY_BUSYBOX_SYMLINKS := $(addprefix $(TARGET_ROOT_OUT)/sbin/,$(filter-out $(exclude),$(notdir $(BUSYBOX_LINKS))))
$(RECOVERY_BUSYBOX_SYMLINKS): BUSYBOX_BINARY := busybox
$(RECOVERY_BUSYBOX_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo "Symlink: $@ -> $(BUSYBOX_BINARY)"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf $(BUSYBOX_BINARY) $@

ALL_DEFAULT_INSTALLED_MODULES += $(RECOVERY_BUSYBOX_SYMLINKS)

#LOCAL_PREBUILT_EXEC := $(TARGET_ROOT_OUT)/bin
#$(LOCAL_PREBUILT_EXEC):
#	cp $(BUSYBOX_PATH)/busybox $(TARGET_ROOT_OUT)/sbin/ -f
#	cp $(LOCAL_PREBUILT_PATH)/adbd $(TARGET_ROOT_OUT)/sbin/ -f
#	cp $(LOCAL_PREBUILT_PATH)/dedupe $(TARGET_ROOT_OUT)/sbin/ -f 

#ALL_DEFAULT_INSTALLED_MODULES += $(LOCAL_PREBUILT_EXEC)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := verifier_test.cpp verifier.cpp

LOCAL_MODULE := verifier_test

#LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_CPPFLAGS := -std=c90
LOCAL_MODULE_TAGS := tests

LOCAL_STATIC_LIBRARIES := libmincrypt 
LOCAL_SHARED_LIBRARIES :=  libcutils libstdc++ libc

include $(BUILD_EXECUTABLE)
#add su binary for recovery 

#include $(CLEAR_VARS)
#LOCAL_MODULE := su.recovery
#LOCAL_MODULE_TAGS := eng debug
#LOCAL_FORCE_STATIC_EXECUTABLE := true
#LOCAL_STATIC_LIBRARIES := libc
#LOCAL_C_INCLUDES := external/sqlite/dist
#LOCAL_SRC_FILES := ../../external/koush/Superuser/Superuser/jni/su/su.c ../../external/koush/Superuser/Superuser/jni/su/activity.c ../../external/koush/Superuser/Superuser/jni/su/utils.c ./su/dbstub.c
#LOCAL_CFLAGS := -DSQLITE_OMIT_LOAD_EXTENSION -DREQUESTOR=\"$(SUPERUSER_PACKAGE)\"
#ifdef SUPERUSER_PACKAGE_PREFIX
#  LOCAL_CFLAGS += -DREQUESTOR_PREFIX=\"$(SUPERUSER_PACKAGE_PREFIX)\"
#endif
#LOCAL_MODULE_CLASS := RECOVERY_EXECUTABLES
#LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/sbin
#include $(BUILD_EXECUTABLE)



#add extra library
#include bionic/libm/Android.mk
#include external/yaffs2/Android.mk
#add from cm7
include $(commands_recovery_local_path)/bmlutils/Android.mk
include $(commands_recovery_local_path)/flashutils/Android.mk
include $(commands_recovery_local_path)/libcrecovery/Android.mk
#end
include $(commands_recovery_local_path)/miui/Android.mk
include $(commands_recovery_local_path)/minelf/Android.mk
#end
include $(commands_recovery_local_path)/minzip/Android.mk
include $(commands_recovery_local_path)/mtdutils/Android.mk
#add from cm7
include $(commands_recovery_local_path)/mmcutils/Android.mk
#end
include $(commands_recovery_local_path)/tools/Android.mk
include $(commands_recovery_local_path)/edify/Android.mk
include $(commands_recovery_local_path)/updater/Android.mk
#include $(commands_recovery_local_path)/applypatch/Android.mk

#add by sndnvaps@gmail.com from Gaojiquan
#include $(commands_recovery_local_path)/supersu/Android.mk
#end 

#add dedupe to replace the tar backup method
include $(commands_recovery_local_path)/dedupe/Android.mk
#add some shell script
include $(commands_recovery_local_path)/utilities/Android.mk
#add yaffs2_static
include $(commands_recovery_local_path)/yaffs2_static/Android.mk
#add digest
include $(commands_recovery_local_path)/digest/Android.mk
#add device conf
include $(commands_recovery_local_path)/devices/Android.mk
#include $(commands_recovery_local_path)/su/Android.mk
commands_recovery_local_path :=

