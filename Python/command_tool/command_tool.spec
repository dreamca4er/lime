# -*- mode: python -*-

block_cipher = None


a = Analysis(['command_tool.py'],
             pathex=['./'],
             binaries=[],
             datas=[('command_template.sql', '.')
             , ('command_types.json', '.')
             , ('connect_config.json', '.')
             , ('existing_operations.sql', '.')
             , ('generate_commands.sql', '.')
             , ('save_changes.sql', '.')
             ],
             hiddenimports=['pyodbc'],
             hookspath=[],
             runtime_hooks=[],
             excludes=['PyQt5.QtBluetooth'],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher,
             noarchive=False)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          [],
          exclude_binaries=True,
          name='command_tool',
          debug=False,
          bootloader_ignore_signals=False,
          strip=False,
          upx=True,
          console=True )
coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas,
               strip=False,
               upx=True,
               name='command_tool')
