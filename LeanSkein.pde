//LeanSkein!
//
//LeanSkein is a lightweight open source mesh slicer.
//LeanSkein will ONLY use options from config.txt
//LeanSkein will not have a GUI.
//Note!  Only takes binary-coded STL.  ASCII
//STL just breaks it for now.
import java.awt.geom.AffineTransform;
import java.awt.geom.Area;
import java.awt.geom.PathIterator;

//The config file takes precedence over these parameters!

float PreScale = 1;
String FileName = "";//"sculpt_dragon.stl";
float XRotate = 0;
boolean debugFlag=false;

String DXFSliceFilePrefix = "dxf_slice";

// Set DXFExportMode=1 to switch render and enable dependent code.
int DXFExportMode = 1;
// Set OpenSCADTestMode=1 to enable OpenSCAD test code.
int OpenSCADTestMode=0;

//Non-GUI-Reachable but in ~config.txt
float PrintHeadSpeed = 2000.0;
float LayerThickness = 0.3;
float Sink = 2.0;
int OperatingTemp = 220;
int FlowRate = 180;




//Display Properties
float BuildPlatformWidth = 100;
float BuildPlatformHeight = 100;
float GridSpacing = 10;
float DisplayScale = 5;


//End of "easy" modifications you can make...
//Naturally I encourage everyone to learn and
//alter the code that follows!

ArrayList Slice;
Mesh STLFile;
PrintWriter output;
float MeshHeight;
// RawDXF pgDxf;

//Configuration File Object
//Hijacks the above variables
//We'll ditch 'em once this works.
Configuration MyConfig = new Configuration();


boolean FileWriteTrigger = false;
boolean STLLoadTrigger = false;
float FileWriteFraction = 0;
float STLLoadFraction = 0;

//Flags
boolean STLLoadedFlag = false;
boolean FileWrittenFlag = false;


int AppWidth = int(BuildPlatformWidth*DisplayScale);
int AppHeight = int(BuildPlatformHeight*DisplayScale);


void setup(){
  size(AppWidth,AppHeight,P2D);

  Slice = new ArrayList();
  

  //For initialization
  //~config.txt
  MyConfig.Load();
  FlowRate = MyConfig.FlowRate;
  OperatingTemp = MyConfig.OperatingTemp;
  PrintHeadSpeed = MyConfig.PrintHeadSpeed;
  LayerThickness = MyConfig.LayerThickness;
  Sink = MyConfig.Sink;
  FileName = MyConfig.FileName;
  //noLoop();
  
  //File Load
  STLLoadTrigger = false;
  STLLoadFraction = 0.0;
      
  STLFile = new Mesh(FileName);

  //Put the mesh in the middle of the platform:
  STLFile.Translate(-STLFile.bx1,-STLFile.by1,-STLFile.bz1);
  STLFile.Translate(-STLFile.bx2/2,-STLFile.by2/2,0);
  STLFile.Translate(0,0,-LayerThickness);  
  STLFile.Translate(0,0,-Sink);
  MeshHeight=STLFile.bz2-STLFile.bz1;
  STLLoadFraction = 1.1;
  STLLoadedFlag = true;
  redraw();  
  background(0,0,255);
  redraw();  


  //File Write
  println("Starting GCODE Write");
  String GCodeFileName = MyConfig.GCodeFile;

  FileWriteTrigger=false;//Only do this once per command.
  FileWriteFraction=0.1;

  ArrayList SliceAreaList = new ArrayList();
  if(debugFlag) println("Slicing...");
  for(float ZLevel = 0;ZLevel<(STLFile.bz2-LayerThickness);ZLevel=ZLevel+LayerThickness)
  {
    Slice ThisSlice = new Slice(STLFile,ZLevel);
    SSArea thisArea;
    int SliceNum = round(ZLevel / LayerThickness);
    thisArea = new SSArea();
    thisArea.setGridScale(0.01);
    if(debugFlag) println("GridScale: "+thisArea.GridScale + "  Slice at: " + ZLevel);
    thisArea.Slice2Area(ThisSlice);
    SliceAreaList.add(SliceNum, thisArea);
  }
  FileWriteFraction=0.2;
  redraw();
  ArrayList ShellAreaList = new ArrayList();
  if(debugFlag) println("Shelling...");
  for(int ShellNum=0;ShellNum<SliceAreaList.size();ShellNum++)
  {
    SSArea thisArea = (SSArea) SliceAreaList.get(ShellNum);
    SSArea thisShell = new SSArea();
    thisShell.setGridScale(thisArea.getGridScale());
    thisShell.add(thisArea);
    thisShell.makeShell(0.25,8);
    SSArea thisSubArea = new SSArea();
    thisSubArea.setGridScale(thisArea.getGridScale());
    thisSubArea.add(thisArea);
    thisSubArea.subtract(thisShell);
    ShellAreaList.add(ShellNum,thisSubArea);
    if(debugFlag) println("Shelled " + ShellNum + " Of " + SliceAreaList.size());
  }
  FileWriteFraction=0.3;
  if(debugFlag) println("Generating Fill...");
  Fill areaFill=new Fill(true,round(BuildPlatformWidth),round(BuildPlatformHeight),MyConfig.FillDensity);
  ArrayList FillAreaList = areaFill.GenerateFill(ShellAreaList);

  if(debugFlag) println("Writing GCode...");
  FileWriteFraction=0.5;
  redraw();
  AreaWriter gcodeOut=new AreaWriter(debugFlag,round(BuildPlatformWidth),round(BuildPlatformHeight));
  gcodeOut.setOperatingTemp(OperatingTemp);
  gcodeOut.setFlowRate(FlowRate);
  gcodeOut.setLayerThickness(LayerThickness);
  gcodeOut.setPrintHeadSpeed(PrintHeadSpeed);
  FileWriteFraction=0.7;
  redraw();

  gcodeOut.ArrayList2GCode(GCodeFileName,SliceAreaList,ShellAreaList,FillAreaList);

  FileWriteFraction=1.5;
  print("\nFinished Slicing!  Bounding Box is:\n");
  print("X: " + CleanFloat(STLFile.bx1) + " - " + CleanFloat(STLFile.bx2) + "   ");
  print("Y: " + CleanFloat(STLFile.by1) + " - " + CleanFloat(STLFile.by2) + "   ");
  print("Z: " + CleanFloat(STLFile.bz1) + " - " + CleanFloat(STLFile.bz2) + "   ");
  if(STLFile.bz1<0)print("\n(Values below z=0 not exported.)");
  MeshHeight=STLFile.bz2-STLFile.bz1;
  STLLoadedFlag = true;
  FileWrittenFlag= true;
  FileWriteTrigger=false;
  

  redraw();  
  background(0,255,0);
  redraw();
}



void draw()
{

}




//Convert the binary format of STL to floats.
float bin_to_float(byte b0, byte b1, byte b2, byte b3)
{
  int exponent, sign;
  float significand;
  float finalvalue=0;
  
  //fraction = b0 + b1<<8 + (b2 & 0x7F)<<16 + 1<<24;
  exponent = (b3 & 0x7F)*2 | (b2 & 0x80)>>7;
  sign = (b3&0x80)>>7;
  exponent = exponent-127;
  significand = 1 + (b2&0x7F)*pow(2,-7) + b1*pow(2,-15) + b0*pow(2,-23);  //throwing away precision for now...

  if(sign!=0)significand=-significand;
  finalvalue = significand*pow(2,exponent);

  return finalvalue;
}


//Display floats cleanly!
float CleanFloat(float Value)
{
  Value = Value * 1000;
  Value = round(Value);
  return Value / 1000;
}



