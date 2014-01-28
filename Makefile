TWEAK_NAME = DoodleMessage
DoodleMessage_FILES = Tweak.mm Doodle/DoodleViewController.m Doodle/DoodleView.m Doodle/DoodleStroke.m Doodle/DoodleImageCropViewController.m Doodle/NSAttributedString+DoodleMessage.m
DoodleMessage_FRAMEWORKS = UIKit CoreGraphics MobileCoreServices

export TARGET=iphone:clang
export ARCHS = armv7 armv7s arm64
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0
export TARGET_IPHONEOS_DEPLOYMENT_VERSION_armv7s = 6.0
export TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 = 6.0
export ADDITIONAL_OBJCFLAGS = -fobjc-arc

include theos/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSMS"
