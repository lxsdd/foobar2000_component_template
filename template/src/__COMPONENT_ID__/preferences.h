#pragma once

#include "guid.h"
#include "resource.h"

namespace __NAMESPACE__ {

extern cfg_bool cfg_enabled;

class preferences_page_instance_impl
    : public preferences_page_instance,
      public CDialogImpl<preferences_page_instance_impl> {
public:
    preferences_page_instance_impl(preferences_page_callback::ptr callback);

    enum { IDD = IDD_COMPONENT_PREFERENCES };

    t_uint32 get_state() override;
    void apply() override;
    void reset() override;
    HWND get_wnd() override { return m_hWnd; }

    BOOL OnInitDialog(CWindow, LPARAM);
    void OnChanged(UINT, int, CWindow);
    LRESULT OnDpiChanged(UINT, WPARAM, LPARAM, BOOL&);

    BEGIN_MSG_MAP_EX(preferences_page_instance_impl)
        MSG_WM_INITDIALOG(OnInitDialog)
        COMMAND_HANDLER_EX(IDC_ENABLE_COMPONENT, BN_CLICKED, OnChanged)
        MESSAGE_HANDLER(WM_DPICHANGED, OnDpiChanged)
    END_MSG_MAP()

private:
    bool has_changed() const;

    preferences_page_callback::ptr m_callback;
    fb2k::CCoreDarkModeHooks m_dark;
};

class preferences_page_impl
    : public ::preferences_page_impl<preferences_page_instance_impl> {
public:
    const char* get_name() override { return "__DISPLAY_NAME__"; }
    GUID get_guid() override { return guids::preferences_page; }
    GUID get_parent_guid() override { return preferences_page::guid_tools; }
};

} // namespace __NAMESPACE__
