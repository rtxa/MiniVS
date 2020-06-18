#if defined _restore_map_included
	#endinput
#endif
#define _restore_map_included

/** 
 * Registers an entity class name in the HL Restore Map API
 *
 * @note This leaves open the possibility to restore more entities than included,
         even custom ones.
 * 
 * @param classname 	Entity index.
 * @param handler		Function name to call for restore.
 *
 * @return				True if the forward was created with success, false otherwise.
 */
native hl_restore_register(const classname[], const handler[]);

/** 
 * Restores an entity to like it was at the beggining of the map.
 * 
 * @param ent 			Entity index.
 *
 * @return				True if the class name provided is registered in
 * 						the API, false otherwise.			
 */
native hl_restore_ent(ent);

/** 
 * Restores all entities with the provided class name just like they were
 * at the beggining of the map.
 * 
 * @param classname 	Entity class name to restore.
 *
 * @return				True if the class name provided is registered in
 * 						the API, false otherwise.
 *
 */
native hl_restore_by_class(const classname[]);

/** 
 * Restores all entities just like they were at the beggining of the map.
 * 
 * @noreturn
 */
native hl_restore_all();