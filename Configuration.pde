//Configuration
//This class acts both as a writer for config.txt
//and as a storage space for all configuration variables.
//Ideally, if you create a new user-settable variable,
//it should be a member of this class and get a line in
//the configuration file.

//~config.txt, obviously

class Configuration {

  float PreScale;
  float XRotate;  
  String FileName;
  String GCodeFile;
  
  float PrintHeadSpeed;
  float LayerThickness;
  float Sink;
  float Diameter;
  float FillDensity;
  int OperatingTemp;
  int FlowRate;
  int PlatformTemp;
  boolean DoShells;
  boolean DoFill;
  
  //Derived configuration values
  float WallWidth;
  
  //config values of last resort
  Configuration() {
    PreScale = 1.0;
    XRotate = 0;
    FileName="";  
    GCodeFile="oops.gcode";
    PrintHeadSpeed = 2000.0;
    LayerThickness = 0.3;
    Sink = 2;
    Diameter = 0.6;
    OperatingTemp = 220;
    PlatformTemp = 120;
    FlowRate = 180;
    FillDensity = 0.1;
    DoFill=false;
    DoShells=false;  
    
    CalcDerivedParameters();
  }

  void CalcDerivedParameters(){
    WallWidth = (3.1415 * Diameter*Diameter / 4)/LayerThickness;
    
  }

  void Load(){
    String[] input = loadStrings("config.txt");
    int index = 0;
    while (index < input.length) {
      String[] pieces = split(input[index], '\t');
      if (pieces.length == 2) {
        if(pieces[0].equals("CONFIG_SCALE"))PreScale=Float.parseFloat(pieces[1]);  
        if(pieces[0].equals("CONFIG_STLFILE"))FileName=pieces[1];  
        if(pieces[0].equals("CONFIG_XROTATE"))XRotate=Float.parseFloat(pieces[1]);  
        if(pieces[0].equals("CONFIG_FILLDENSITY"))FillDensity=Float.parseFloat(pieces[1]);
        if(pieces[0].equals("MACHINE_OPTEMP"))OperatingTemp=Integer.parseInt(pieces[1]);  
        if(pieces[0].equals("MACHINE_FLOWRATE"))FlowRate=Integer.parseInt(pieces[1]);  
        if(pieces[0].equals("CONFIG_SINK"))Sink=Float.parseFloat(pieces[1]);  
        if(pieces[0].equals("MACHINE_PRINTHEADSPEED"))PrintHeadSpeed=Float.parseFloat(pieces[1]);  
        if(pieces[0].equals("MACHINE_LAYERTHICKNESS"))LayerThickness=Float.parseFloat(pieces[1]);  
        if(pieces[0].equals("MACHINE_PLATFORMTEMP"))PlatformTemp=Integer.parseInt(pieces[1]);  
        if(pieces[0].equals("CONFIG_DOSHELLS"))DoShells = (Integer.parseInt(pieces[1])==1);  
        if(pieces[0].equals("CONFIG_DOFILL"))DoFill = (Integer.parseInt(pieces[1])==1);  
        if(pieces[0].equals("MACHINE_DIAMETER"))Diameter = (Float.parseFloat(pieces[1]));
        if(pieces[0].equals("CONFIG_GCODEFILE"))GCodeFile=pieces[1];  
        
      }
      index=index+1;
    }
    CalcDerivedParameters();
  }
 

}


