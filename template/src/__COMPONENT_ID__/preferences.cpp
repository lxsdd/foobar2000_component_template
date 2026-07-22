#include "stdafx.h"
#include "preferences.h"

namespace __NAMESPACE__ {

cfg_bool cfg_enabled(guids::cfg_enabled, true);

preferences_page_instance_impl::preferences_page_instance_impl(
    preferences_page_callback::ptr callback)
    : m_callback(std::move(callback)) {}

BOOL preferences_page_instance_impl::OnInitDialog(CWindow, LPARAM) {
    m_dark.AddDialogWithControls(m_hWnd);
    CheckDlgButton(IDC_ENABLE_COMPONENT, cfg_enabled ? BST_CHECKED : BST_UNCHECKED);
    return TRUE;
}

bool preferences_page_instance_impl::has_changed() const {
    return (IsDlgButtonChecked(IDC_ENABLE_COMPONENT) == BST_CHECKED) != static_cast<bool>(cfg_enabled);
}

t_uint32 preferences_page_instance_impl::get_state() {
    t_uint32 state = preferences_state::resettable;
    if (has_changed()) state |= preferences_state::changed;
    return state;
}

void preferences_page_instance_impl::apply() {
    cfg_enabled = IsDlgButtonChecked(IDC_ENABLE_COMPONENT) == BST_CHECKED;
    if (m_callback.is_valid()) m_callback->on_state_changed();
}

void preferences_page_instance_impl::reset() {
    CheckDlgButton(IDC_ENABLE_COMPONENT, BST_CHECKED);
    if (m_callback.is_valid()) m_callback->on_state_changed();
}

void preferences_page_instance_impl::OnChanged(UINT, int, CWindow) {
    if (m_callback.is_valid()) m_callback->on_state_changed();
}

LRESULT preferences_page_instance_impl::OnDpiChanged(UINT, WPARAM, LPARAM l_param, BOOL&) {
    const auto* suggested = reinterpret_cast<const RECT*>(l_param);
    if (suggested != nullptr) {
        SetWindowPos(nullptr,
            suggested->left,
            suggested->top,
            suggested->right - suggested->left,
            suggested->bottom - suggested->top,
            SWP_NOACTIVATE | SWP_NOZORDER);
    }
    return 0;
}

static preferences_page_factory_t<preferences_page_impl> g_preferences_page_factory;

} // namespace __NAMESPACE__
