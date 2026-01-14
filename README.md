# Silly Panorama Tool

take screenshots around you in Minecraft with Figura and stitch them into one for a panorama

### Required tools

- Figura 0.1.5
- Blender 5.0

Blender is used to render the final image product, Figura is used to only save up the screenshots into one model that can then be rendered into your desired panorama.

## How to use

1. Take a bunch of screenshots using the keybind `v` or through the action wheel.
2. Export the model with the action wheel button, its going to create a folder in `figura/data/panorama-model/` wherever your figura folder is located.
3. Pick which one you want to do from the two optiosn bellow

> [!IMPORTANT]
> The image rendered is 4096 x 2048, or a 4k image with a 2:1 aspect ratio  
> it is recommended to save the image as a lossy format like `.jpg` or `.webp`  
> if youre saving it as a `.png`, save it as RGB to avoid wasting the alpha channel because its not used in the final image

### Equirectangular (360 image)
4. Open the `renderer_equirectangular.blend` then hit File > Import > Wavefront OBJ and select the `figura/data/panorama-model/model.obj` file.
5. Hit Render > Render Image
6. In the Blender Render window, **hit Image > Save**
7. And youre done!


### Cubemap (for Minecraft Resource packs)

4. Open the `renderer_cubemap.blend` then hit **File > Import > Wavefront OBJ** and select the `figura/data/panorama-model/model.obj` file.
5. Hit Render > Render Animation
6. In the same folder as where the blender project itself is, 6 new files will appear after its done rendering, `panorama_0.png` to `panorama_5.png`
   > [!NOTE]
   > The Steps going forward will be for making a resource pack with the given panorama
7. Alongside this avatar is a `panorama_pack` folder, duplicate that folder and give it a unique name
8. Copy all `panorama_0-5.png` files into your panorama pack folder in this location: `your_panorama_pack/assets/minecraft/textures/gui/title/background/`
9. Move that folder into your minecraft resource pack folder (`.minecraft/resourcepacks/`)`
10. try it on and youre done!

> [!WARNING]
> Minecraft might warn you saying that the resource pack is outdated, it can be ignored.