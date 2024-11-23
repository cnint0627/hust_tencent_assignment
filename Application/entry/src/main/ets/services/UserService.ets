// entry/src/main/ets/services/UserService.ets
import auth, { AuthUser } from '@hw-agconnect/auth';
import type { UserInfo } from '../common/UserInfo';
import cloud from "@hw-agconnect/cloud";

export class UserService {
  private static instance: UserService;
  private currentUser: UserInfo | null = null;

  private constructor() {}

  public static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService();
    }
    return UserService.instance;
  }

  public async getCurrentUserInfo(): Promise<UserInfo | null> {
    if (this.currentUser) {
      return this.currentUser;
    }

    try {
      const user: AuthUser | null = await auth.getCurrentUser();
      if (!user) {
        return null;
      }

      // 调用云函数获取用户信息
      const res = await cloud.callFunction({
        name: 'get-user-info',
        version: '$latest',
        params: {
          uid: user.getUid(),
          phoneNumber: user.getPhone()
        }
      });

      if (res.getValue().code === 0) {
        this.currentUser = res.getValue().data;
        return this.currentUser;
      }
      return null;
    } catch (error) {
      console.error('Get user info failed:', error);
      return null;
    }
  }

  public clearCurrentUser() {
    this.currentUser = null;
  }
}