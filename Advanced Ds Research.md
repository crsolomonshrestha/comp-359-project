# Advanced Data Structure for 3D Collision Detection

## Octree
Octrees reduce collision detection from O(n²) to approximately O(log n) by recursively subdividing 3D space and limiting comparisons to nearby nodes (Zhou et al., 2014).

**Source:** https://link.springer.com/article/10.1007/s00371-014-0954-1  
**Note:** Springer article — requires institutional or paid access.

---

## R-Tree
R-Trees achieve O(log n) average search complexity due to their balanced tree structure, but may degrade to O(n) in worst-case overlapping regions (Nüchter & Hertzberg, 2015).

**Source:** https://www.sciencedirect.com/science/article/abs/pii/S1474034615000348  
**Note:** ScienceDirect — subscription required.

---

## Spatial Hashing (Hierarchical)
Spatial hashing provides O(1) average lookup time using hash tables, but worst-case O(n) when many objects map to the same cell. Hierarchical hashing improves distribution efficiency (Eitz & Lixu, 2007).

**Source:** https://ieeexplore.ieee.org/abstract/document/4273369  
**Note:** IEEE — requires institutional access.

---

## Bounding Volume Hierarchy (BVH)
BVH reduces collision detection from O(n²) to approximately O(log n) by hierarchically pruning non-intersecting regions during traversal (Sulaiman & Bade, 2018).

**Source:** https://books.google.ca/books?id=d9CPDwAAQBAJ  
**Note:** Google Books — partial access, may require purchase.

---

# References (APA 7th Edition)

Zhou, K., Gong, M., Huang, X., & Guo, B. (2014). *An adaptive octree grid for GPU-based collision detection of deformable objects*. The Visual Computer, 30, 729–738. https://doi.org/10.1007/s00371-014-0954-1  

Nüchter, A., & Hertzberg, J. (2015). *Towards semantic maps for mobile robots*. Journal of Spatial Information Science. https://www.sciencedirect.com/science/article/abs/pii/S1474034615000348  

Eitz, M., & Lixu, G. (2007). *Hierarchical spatial hashing for real-time collision detection*. IEEE Xplore. https://ieeexplore.ieee.org/abstract/document/4273369  

Sulaiman, H. A., & Bade, A. (2018). *Bounding volume hierarchies for collision detection*. In Computer graphics. https://books.google.ca/books?id=d9CPDwAAQBAJ  