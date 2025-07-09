   ```mermaid
   flowchart TD
       A[.norm File]
       A --> B["Tokenizer<br/>(Converts text into tokens)"]
       B --> C["Parser<br/>(Builds structured components)"]
       C --> D["RenderableNode[]<br/>(Universal intermediate format)"]
       D --> E1["HTML<br/>(Emitter)"]
       D --> E2["JSX<br/>(Emitter)"]
       D --> E3["OpenGL<br/>(Emitter)"]
   ```
   
   **Pipeline Overview:**
   
   1. **.norm File**  
      _This is the input/source file that contains the Norm syntax_<br>
      _It’s a human-readable format that describes the UI components and their properties_<br>
      _It’s similar to a JSON or YAML file but tailored for UI definitions_
   2. **Tokenizer**  
      _Converts text into tokens_
   
   3. **Parser**  
      _Builds structured components_
   
   4. **RenderableNode[]**  
      _Universal intermediate format_ <br>
      _It’s essentially the machine-readable version of the .norm file_
   
   5. **Emitters:**  
      - **HTML**
      - **JSX**
      - **OpenGL**
   
   _All emitters are pluggable and consume the universal format._


   ## To-Do List
   - [ ] Implement error handling
   - [ ] Add logging
   - [ ] Optimize performance
   - [ ] Implement a more robust build system
   - [ ] Add more comprehensive tests
   - [ ] Implement the GUI layer
   - [ ] Add support for more complex UI components
   - [ ] Improve documentation and examples
   - [ ] Implement a configuration system for NormEngine
   - [ ] Add support for themes and styles
   - [ ] Implement a plugin system for NormEngine
   - [ ] Add support for animations and transitions
   - [ ] Implement a [debugging tool](https://github.com/EpicGamesExt/raddebugger) for NormEngine
   - [ ] Smart checker for NormEngine Components e.g `<Button>` should have `onClick` property and if the `onClick` property is not present, it should throw an error/prompt you to create one.
   - [ ] Implement a linter for NormEngine 
   - [ ] Add support for minification and optimization of exported files