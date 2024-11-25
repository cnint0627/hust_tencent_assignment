// cloud/functions/get-user-info/index.js
import { cloud, CloudDBCollection } from '@hw-agconnect/cloud-server';//引入Server SDK依赖
import { WorkoutRecord } from './WorkoutRecord';

// ZONE_NAME为存储区名称
const ZONE_NAME = "default";

let myHandler = async function (event, context, callback, logger) {
  try {
    const collection: CloudDBCollection<WorkoutRecord> = cloud.database({ zoneName: ZONE_NAME }).collection(WorkoutRecord);
    const { uid } = JSON.parse(event.body) // 这里有点坑，params传入的参数在event.body中，需要手动解析

    const recordResult = await collection.query()
      .equalTo("uid", uid)
      .orderByDesc("createTime")  // 按创建时间降序排序
      .get();


    callback({
      code: 0,
      message: 'Success',
      data: recordResult
    });
  } catch (error) {
    callback({
      code: -1,
      message: error.message,
      data: null
    });
  }
};

export {myHandler}