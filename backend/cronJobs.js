import cron from "node-cron";
import DeviceLog from "./models/deviceLog.model.js"; // Adjust the path as necessary
import Device from "./models/device.model.js"; // Adjust the path as necessary

// Function to clean up device logs
export const cleanupDeviceLogs = async () => {
  try {
    const devices = await DeviceLog.distinct("device"); // Get unique device IDs

    for (const deviceId of devices) {
      // Get the current time in UTC and calculate the start of the current 15-minute interval
      const now = new Date(); // This will be in UTC
      const currentIntervalStart = new Date(
        now.getTime() - (now.getMinutes() % 15) * 60000
      ); // Start of the current interval

      // Find all log entries within the current 15-minute interval
      const logsInInterval = await DeviceLog.find({
        device: deviceId,
        timestamp: {
          $gte: currentIntervalStart,
          $lt: new Date(currentIntervalStart.getTime() + 15 * 60000),
        },
      }).sort({ timestamp: -1 }); // Sort to get the most recent log

      // If there are logs in the current interval, keep the most recent one and delete the rest
      if (logsInInterval.length > 0) {
        const mostRecentLog = logsInInterval[0]; // The first one after sorting is the most recent

        // Delete all other logs in the current interval
        await DeviceLog.deleteMany({
          device: deviceId,
          timestamp: {
            $gte: currentIntervalStart,
            $lt: new Date(currentIntervalStart.getTime() + 15 * 60000),
          },
          _id: { $ne: mostRecentLog._id }, // Exclude the most recent log
        });
      }
    }

    console.log(
      "Old device logs cleaned up successfully, keeping one log per 15-minute interval."
    );
  } catch (error) {
    console.error("Error cleaning up device logs:", error);
  }
};

// Schedule a task to run every 15 minutes
cron.schedule("*/15 * * * *", cleanupDeviceLogs);
