# imageJ-extended-geometries
Simple macro to add historically common descriptions such as area equivalent diameter and fiber thickness to the ImageJ Results table using the macro in this: <a href="https://github.com/peterjlee/imageJ-extended-geometries"  Title = "Applied Superconductivity Center Extended Geometrical Analyses Macro Directory" >directory</a>.</p><p>The additional measurements in this version are:</p>
<p>&nbsp;&nbsp;&nbsp;Local grain boundary density (assuming each grain boundary is shared by two grains).<br />
&nbsp;&nbsp;&nbsp;Area equivalent diameter  (AKA Heywood diameter): The &quot;diameter&quot; of an object obtained from the area assuming a circular geometry.<br />
&nbsp;&nbsp;&nbsp;Perimeter equivalent diameter: The &quot;diameter&quot; calculated from the perimeter  assuming a circular geometry.<br />
&nbsp;&nbsp;&nbsp;Round end ribbon thickness from repeating half-annulus (Lee &amp; Jablonski LTSW'94).<br />  &nbsp;&nbsp;&nbsp;Two calculated fiber widths obtained from the fiber length from <a href="http://www.springer.com/us/book/9781461278689">John C. Russ, Computer Assisted Microscopy, page 189.</a><br />
&nbsp;&nbsp;&nbsp;Fiber length from fiber width (Lee and Jablonski LTSW'94; modified from the formula in  <a href="https://www.crcpress.com/The-Image-Processing-Handbook-Seventh-Edition/Russ-Neal/p/book/9781498740265">John C. Russ, Image Processing Handbook 7th Ed.</a> Page 612).<br />
&nbsp;&nbsp;&nbsp;Two estimates of fiber length obtained from the formulas in <a href="http://www.springer.com/us/book/9781461278689">John C. Russ, Computer Assisted Microscopy page, 189.</a><br />
&nbsp;&nbsp;&nbsp;Hexagonal geometries more appropriate to close-packed structures than ellipses.<br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;HexSide = sqrt((2*Areas)/(3*sqrt(3))) <br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;HexPerimeter = 6 * HexSide <br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Hexagonal Shape Factor "HSF", i, abs(((Ps[1] * Ps[1])/A[i])-13.856): Hexagonal Shape Factor from Behndig et al. https://iovs.arvojournals.org/article.aspx?articleid=2122939 and Collin and Grabsch (1982) https://doi.org/10.1111/j.1755-3768.1982.tb05785.x <br />
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Hexagonal Shape Factor Ratio "HSFR", i, abs(13.856/((Ps[1] * Ps[1])/A[i])): as above but expressed as a ratio like circularity, with 1 being an ideal hexagaon. <br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;HexPerimeter = 6 * HexSide <br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Hexagonality = 6*HexSide/Perimeter<br />
&nbsp;&nbsp;&nbsp;Full Feret coordinate listing using new Roi.getFeretPoints macro function added in ImageJ 1.52m<br />
A preference file is saved and retrieved so that favorite geometries can be retained.</p>
<p><img src="https://fs.magnet.fsu.edu/~lee/asc/ImageJUtilities/IA_Images/ASC_Extended_Geometries_Menu_500x344.png" alt="ASC_Extended Geometries Menu" width="500" height="344" /> </p>
