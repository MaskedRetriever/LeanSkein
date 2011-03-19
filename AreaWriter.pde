// Class to write Areas out to DXF and other formats.
import processing.dxf.*;

class AreaWriter {

  boolean debugFlag;
  int Width;
  int Height;

  float OperatingTemp;
  float FlowRate;
  float LayerThickness;
  float PrintHeadSpeed;

  PrintWriter GCodeOutput;

  AreaWriter(boolean bFlag, int iWidth, int iHeight) {
    debugFlag=bFlag;
    Width=iWidth;
    Height=iHeight;
  }

  void setOperatingTemp(float aFloat) {
    OperatingTemp=aFloat;
  }
  void setFlowRate(float aFloat) {
    FlowRate=aFloat;
  }
  void setLayerThickness(float aFloat) {
    LayerThickness=aFloat;
  }
  void setPrintHeadSpeed(float aFloat) {
    PrintHeadSpeed=aFloat;
  }


  void GCodeInit(String aString) {
    GCodeOutput = createWriter(aString);
  }

  void GCodeWriteHeader() {
    GCodeOutput.println("(This is a LeanSkein-Sliced File)");
    GCodeOutput.println("G21");
    GCodeOutput.println("G90");
    GCodeOutput.println("M103");
    GCodeOutput.println("M105");
    GCodeOutput.println("M104 s"+OperatingTemp);
    GCodeOutput.println("M109 s"+FlowRate);
    GCodeOutput.println("M101");
    GCodeOutput.println("G1 X20.0 Y20.0 Z0.0 F"+PrintHeadSpeed/2);
    GCodeOutput.println("G1 X0.0 Y20.0 Z0.0 F"+PrintHeadSpeed/2);
  }

  void GCodeWriteFooter() {
    GCodeOutput.flush();
    GCodeOutput.close();
  }

  void GCodeWriteArea(int SliceNum, SSArea thisArea) {
    PathIterator pathIter=thisArea.getPathIterator(new AffineTransform());
    float[] newCoords={0.0,0.0,0.0,0.0,0.0,0.0};
    float[] prevCoords={0.0,0.0,0.0,0.0,0.0,0.0};
    float[] startCoords={0.0,0.0,0.0,0.0,0.0,0.0};
    int segType=pathIter.currentSegment(startCoords);
    // Move to starting point
    GCodeOutput.println("M103");
    GCodeOutput.println("G1 X" + startCoords[0] + " Y" + startCoords[1] + " Z" + SliceNum*LayerThickness + " F" + PrintHeadSpeed);
    GCodeOutput.println("M101");
    segType=pathIter.currentSegment(prevCoords);
    pathIter.next();
    while(!pathIter.isDone()) {
      segType=pathIter.currentSegment(newCoords);
      if(segType == PathIterator.SEG_LINETO ) {
        // draw line from prevCoords to newCoords
        GCodeOutput.println("G1 X" + newCoords[0] + " Y" + newCoords[1] + " Z" + SliceNum*LayerThickness + " F" + PrintHeadSpeed);
        segType=pathIter.currentSegment(prevCoords);
      } else if(segType==PathIterator.SEG_CLOSE ) {
        // last segment of current path
        GCodeOutput.println("G1 X" + newCoords[0] + " Y" + newCoords[1] + " Z" + SliceNum*LayerThickness + " F" + PrintHeadSpeed);
        GCodeOutput.println("G1 X" + startCoords[0] + " Y" + startCoords[1] + " Z" + SliceNum*LayerThickness + " F" + PrintHeadSpeed);
        segType=pathIter.currentSegment(prevCoords);
      } else if(segType==PathIterator.SEG_MOVETO ) {
        // move to next starting point
        segType=pathIter.currentSegment(prevCoords);
        GCodeOutput.println("M103");
        GCodeOutput.println("G1 X" + newCoords[0] + " Y" + newCoords[1] + " Z" + SliceNum*LayerThickness + " F" + PrintHeadSpeed);
        GCodeOutput.println("M101");
        segType=pathIter.currentSegment(prevCoords);
        segType=pathIter.currentSegment(startCoords);
      } else {
        // unknown segment type
        segType=pathIter.currentSegment(prevCoords);
      }
      pathIter.next();
    }
    GCodeOutput.println("M103");
  }

  void GCodeWriteModel(ArrayList SliceAreaList, ArrayList ShellAreaList, ArrayList FillAreaList) {
    for(int SliceNum=0;SliceNum<SliceAreaList.size();SliceNum++)
    {
      SSArea thisArea;
      if((ShellAreaList.size()>0)&MyConfig.DoShells) {
        thisArea = (SSArea) ShellAreaList.get(SliceNum);
        if(!thisArea.isEmpty()) GCodeWriteArea(SliceNum, thisArea);
      }
      if((FillAreaList.size()>0)&MyConfig.DoFill) {
        thisArea = (SSArea) FillAreaList.get(SliceNum);
        if(!thisArea.isEmpty()) GCodeWriteArea(SliceNum, thisArea);
      }
      if(SliceAreaList.size()>0) {
        thisArea = (SSArea) SliceAreaList.get(SliceNum);
        if(!thisArea.isEmpty()) GCodeWriteArea(SliceNum, thisArea);
      }
    }
  }

  void ArrayList2GCode(String FileName, ArrayList SliceAreaList, ArrayList ShellAreaList, ArrayList FillAreaList) {
    GCodeInit(FileName);
    GCodeWriteHeader();
    GCodeWriteModel(SliceAreaList,ShellAreaList,FillAreaList);
    GCodeWriteFooter();  
  }

}

