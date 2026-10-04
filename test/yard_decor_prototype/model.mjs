export const spots=[{x:.30,y:.73},{x:.52,y:.79},{x:.71,y:.68}];
// Normalized coordinates are experimental composition anchors, not walkable ground.
export class Decor {
 constructor(){this.mode='spots';this.placed=null;this.preview=null;this.id='fixture:decor:one';}
 valid(p){return p&&Number.isFinite(p.x)&&Number.isFinite(p.y)&&p.x>=.18&&p.x<=.80&&p.y>=.62&&p.y<=.85;}
 choose(p){if(!this.valid(p))return false;this.preview={x:p.x,y:p.y};return true;}
 cancel(){this.preview=null;}
 confirm(){if(!this.preview)return false;this.placed={...this.preview};this.preview=null;return true;}
 remove(){this.placed=null;this.preview=null;}
 setMode(m){if(!['spots','free'].includes(m))return false;this.mode=m;this.cancel();return true;}
}
