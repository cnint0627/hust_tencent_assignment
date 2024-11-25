// entry/src/main/ets/services/WorkoutService.ets
import auth, { AuthUser } from '@hw-agconnect/auth';
import type { WorkoutRecord } from '../common/WorkoutRecord';
import cloud from "@hw-agconnect/cloud";

export class WorkoutService {
  private static instance: WorkoutService;

  private constructor() {}

  public static getInstance(): WorkoutService {
    if (!WorkoutService.instance) {
      WorkoutService.instance = new WorkoutService();
    }
    return WorkoutService.instance;
  }

  public async getRecordList(): Promise<Array<WorkoutRecord>> {
    try {
      const user: AuthUser | null = await cloud.auth().getCurrentUser();
      if (!user) {
        return [];
      }

      // 调用云函数获取记录列表
      const res = await cloud.callFunction({
        name: 'get-record-list',
        version: '$latest',
        params: {
          uid: user.getUid()
        }
      });
      if (res.getValue().code === 0) {
        return res.getValue().data;
      }
      return [];
    } catch (error) {
      console.error('Get record list failed:', error);
      return []
    }
  }

  public async saveWorkoutRecord(workoutRecord: WorkoutRecord): Promise<boolean> {
    try {
      const user: AuthUser | null = await cloud.auth().getCurrentUser();
      if (!user) {
        return false;
      }

      // 调用云函数保存运动记录
      const res = await cloud.callFunction({
        name: 'save-workout-record',
        version: '$latest',
        params: {
          uid: user.getUid(),
          workoutType: workoutRecord.workoutType,
          totalTime: workoutRecord.totalTime,
          totalDistance: workoutRecord.totalDistance,
          averageSpeed: workoutRecord.averageSpeed,
          snapshotUrl: workoutRecord.snapshotUrl
        }
      });

      if (res.getValue().code === 0) {
        return true
      }
      return false;
    } catch (error) {
      console.error('Save workout record failed:', error);
      return false;
    }
  }
}