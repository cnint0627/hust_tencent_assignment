// entry/src/main/ets/common/WorkoutRecord.ets
export interface WorkoutRecord {
  workoutType: string;
  totalTime: number;  // 总时间（秒）
  totalDistance: number;  // 总距离（公里）
  averageSpeed: number;  // 平均速度（公里/小时）
  createTime: Date;  // 记录时间戳
  segments: Array<Array<[number, number]>>;  // 运动轨迹段
}