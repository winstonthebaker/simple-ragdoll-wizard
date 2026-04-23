How to use:
Enable the plugin.

Create an inherited scene using the model you wish to create a ragdoll for.
Add the "RagdollGenerator" node as a direct child of the Skeleton3D. It must be a direct child or it won't work.
Configure the ragdoll profile using the instructions below.
Click "Generate Ragdoll."
Once you've made your ragdoll and are happy with it, you can just delete the "RagdollGenerator" node as it isn't doing anything. 
Note that in order to activate a ragdoll for physics, you will need to call physical_bones_start_simulation() on the PhysicalBoneSimulator3D.

Ragdoll Profile: The generator takes a Ragdoll Profile (there should be a humanoid one by default). This is a dictionary of bone names to bone configurations. If you expand it or look at the resource in the RagdollProfiles folder, there should be a Dictionary with bone name strings as keys and bone configurations as values.

Note that in order for the generator to work properly, your bones names must match those in the Dictionary. You can ensure this by either:
	1. Making your own Ragdoll Profile resource to match your skeleton.
	2. Renaming your bones to match the bone names in the existing profile (See Bone Name Retargeting).
	3. Using a Bone Map to match your current bone names to the appropriate names (See Bone Name Retargeting).

Bone Name Retargeting: 
	To make steps 2 or 3 easier, this addon makes use of Godot's built in bone retargeting system. 
	To use this, open the advanced import settings dialog for your model and click on the "Skeleton3D" node. 
	There should be an option called "Retarget". Make a new bone map and match up your bones appropriately.
	Now, you can either enable the "Bone Renamer" option or right click the BoneMap resource and save it somewhere.
	If you renamed, just reimport and the names should be correct for the default humanoid ragdoll profiles.
	If you chose to use a Bone Map, add the Bone Map resource to the Ragdoll Generator.

Configuring Bones:
	Each value in the Ragdoll Profile is a RagdollBoneConfig resource that you can modify. The "Leaf Bone" is a bone in the chain that will be used to help determine the collider size. You can also set a Joint Config with different joint types and parameters.
	
Mirroring Colliders:
	The "Mirror Colliders Left to Right" button will attempt to make the colliders on the right side of the model reference those on the left side of the model for their shapes positions. This is appropriate for symmetric models. The collider shapes should reference the same side so they will update in real time, but you will need to click this again after making position adjustments. 

Note on Blender Rigify armatures:
	Rigify armatures have by default a hierarchy that is not suitable for game engines because bones don't share a common root in the hierarchy. If you use a "rigify" armature, your ragdoll will probably fall to pieces once you start physics.
	I recommend the "Rigodotify" addon by catprisbrey. There are thorough instructions on how to get it working in Blender in the github repo.
	
	https://github.com/catprisbrey/Rigodotify
