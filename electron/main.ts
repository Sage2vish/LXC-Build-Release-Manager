import { app, BrowserWindow, shell } from 'electron';
import * as path from 'path';

const isDev = !app.isPackaged;
const devUrl = 'http://localhost:5173';

function createWindow() {
  const win = new BrowserWindow({
    width: 1600,
    height: 1024,
    minWidth: 1240,
    minHeight: 820,
    title: 'Build Manager',
    backgroundColor: '#14161a',
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 20, y: 18 },
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  if (isDev) {
    win.loadURL(devUrl);
    win.webContents.openDevTools({ mode: 'detach' });
  } else {
    win.loadFile(path.join(app.getAppPath(), 'dist', 'index.html'));
  }

  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
