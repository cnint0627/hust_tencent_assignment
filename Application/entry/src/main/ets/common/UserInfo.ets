// entry/src/main/ets/common/UserInfo.ets
export interface UserInfo {
  uid: string;            // AGConnect用户ID
  phoneNumber: string;    // 手机号
  nickname: string;       // 昵称
  avatarUrl?: string;     // 头像URL
  createTime: Date;       // 创建时间
  updateTime: Date;       // 更新时间
}