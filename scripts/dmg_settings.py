import os

# --- Basic Settings ---
filename = os.environ.get('DMG_NAME', 'Zonely.dmg')
volume_name = os.environ.get('VOL_NAME', 'Zonely Installer')
app_path = os.environ.get('APP_PATH', 'dist/Zonely.app')
background_path = os.environ.get('BG_IMAGE', 'art/background.png')

# --- Window Settings ---
# Lungo style: clean, centered, white
window_rect = ((100, 100), (600, 400))
default_view = 'icon-view'
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 180

# --- Icon Settings ---
icon_size = 120
text_size = 14

# Positioning (x, y)
# In dmgbuild, coordinates are relative to the window
icon_locations = {
    os.path.basename(app_path): (160, 200),
    'Applications': (440, 200)
}

# --- Background ---
background = background_path

# --- Contents ---
# These are the files that will be in the DMG
files = [app_path]
symlinks = {'Applications': '/Applications'}

# --- Advanced ---
# This ensures the DMG works well on high-DPI screens
retina = True
format = 'UDZO' # Compressed, read-only
compression_level = 9
