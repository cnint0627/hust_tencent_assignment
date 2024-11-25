// cloud/functions/get-user-info/index.js
import { cloud, CloudDBCollection } from '@hw-agconnect/cloud-server';//引入Server SDK依赖
import { WorkoutRecord } from './WorkoutRecord';

// ZONE_NAME为存储区名称
const ZONE_NAME = "default";

let myHandler = async function (event, context, callback, logger) {
  try {
    const collection: CloudDBCollection<WorkoutRecord> = cloud.database({ zoneName: ZONE_NAME }).collection(WorkoutRecord);
    const { uid, workoutType, totalTime, totalDistance, averageSpeed, snapshotUrl } = JSON.parse(event.body) // 这里有点坑，params传入的参数在event.body中，需要手动解析

    const newRecord = {
      uid: uid,
      workoutType: workoutType,
      totalTime: totalTime,
      totalDistance: totalDistance,
      averageSpeed: averageSpeed,
      snapshotUrl: snapshotUrl,
      createTime: new Date()
    };

    await collection.insert(newRecord);

    callback({
      code: 0,
      message: 'Workout record saved',
      data: null
    });
  } catch (error) {
    console.error('Error in saveWorkoutRecord:', error);
    callback({
      code: -1,
      message: error.message,
      data: null
    });
  }
};

export {myHandler}