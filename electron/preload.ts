import { contextBridge } from 'electron';

contextBridge.exposeInMainWorld('buildManager', {
  platform: process.platform,
});
