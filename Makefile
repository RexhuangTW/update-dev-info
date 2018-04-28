#
# Copyright (C) 2018 netike.huang@gmail.com
#
# 

include $(TOPDIR)/rules.mk

PKG_NAME:=update_dev_info
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk


define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Others
  SUBMENU:=Packages
  TITLE:=update dev info
  DEPENDS:=+@BUSYBOX_DEFAULT_ARP
endef

define Build/Prepare
endef

define Build/Compile
endef


define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
