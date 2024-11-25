// entry/src/main/ets/services/SettingsService.ets
import preferences from '@ohos.data.preferences';
import { Settings } from '../common/Settings';

export class SettingsService {
  private static instance: SettingsService;
  private static readonly PREFERENCES_NAME: string = 'settings';

  private constructor() {}

  public static getInstance(): SettingsService {
    if (!SettingsService.instance) {
      SettingsService.instance = new SettingsService();
    }
    return SettingsService.instance;
  }

  public async getSettings(): Promise<Settings> {
    try {
      const context = getContext(this);
      const pref = await preferences.getPreferences(context, SettingsService.PREFERENCES_NAME);
      return {
        notification: (await pref.get('notification', true)) as boolean,
        sound: (await pref.get('sound', true)) as boolean,
        vibration: (await pref.get('vibration', true)) as boolean
      };
    } catch (error) {
      console.error('获取设置失败:', error);
      return {
        notification: true,
        sound: true,
        vibration: true
      };
    }
  }

  public async saveSettings(settings: Settings): Promise<boolean> {
    try {
      const context = getContext(this);
      const pref = await preferences.getPreferences(context, SettingsService.PREFERENCES_NAME);
      await pref.put('notification', settings.notification);
      await pref.put('sound', settings.sound);
      await pref.put('vibration', settings.vibration);
      await pref.flush();
      return true;
    } catch (error) {
      console.error('保存设置失败:', error);
      return false;
    }
  }
}