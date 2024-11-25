// entry/src/main/ets/common/WorkoutRecord.ets
export interface WorkoutRecord {
  // 一般字段
  workoutType: string;  // 运动种类
  totalTime: number;  // 总时间（秒）
  totalDistance: number;  // 总距离（公里）
  averageSpeed: number;  // 平均速度（公里/小时）
  snapshotUrl: string;  // 云存储的url
  // 数据库对象字段
  uid: string;
  recordId: number;
  createTime: Date;
}