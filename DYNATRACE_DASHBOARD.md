# Creating Your Dynatrace Dashboard

Since we have established the **AWS Integration**, Dynatrace automatically collects metrics. You can now create a dashboard to visualize them.

## Option 1: The "AWS Overview" Preset (Fastest)
1.  Go to **Dynatrace Menu -> Dashboards**.
2.  Click **Create Dashboard**.
3.  Name it `AWS Status`.
4.  In the tile browser, search for "AWS".
5.  Drag the **AWS Infrastructure** or **EC2 Overview** tiles onto the canvas.
    *   *Note: It might take 10-15 minutes for data to populate fully.*

## Option 2: Custom Metrics
1.  On your Dashboard, click **+ Add Tile**.
2.  Choose **Honeycomb** or **Graph**.
3.  Click **Configure**.
4.  Select Metric:
    *   `aws.ec2.cpuutilization` (CPU)
    *   `aws.ec2.networkin` / `networkout`
    *   `aws.dynamodb.consumedreadcapacityunits`
5.  Split by: `Dimension: InstanceId` or `Name`.

## Troubleshooting "No Data"
If the dashboard is empty:
1.  Go to **Settings -> Cloud -> AWS**.
2.  Ensure your connection is **Green**.
3.  Edit the connection and ensure "Metric Collection" is **Enabled**.
4.  Wait up to 15 minutes.
