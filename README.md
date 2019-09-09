# imageJ-extended-geometries
Simple macro to illustrate how historically common descriptions such as area equivalent diameter and fiber thickness as well as new geometries can be added to an ImageJ Results table: <a href="https://github.com/peterjlee/imageJ-extended-geometries"  Title = "Applied Superconductivity Center Extended Geometrical Analyses Macro Directory" >directory</a>.</p><p>The additional measurements in this version are:</p>
<p>&nbsp;&nbsp;&nbsp;Interfacial density (assuming each interface is shared by two objects - e.g. grain boundary density).<br />
&nbsp;&nbsp;&nbsp;Area equivalent diameter  (AKA Heywood diameter): The &quot;diameter&quot; of an object obtained from the area assuming a circular geometry.<br />
&nbsp;&nbsp;&nbsp;Perimeter equivalent diameter: The &quot;diameter&quot; calculated from the perimeter  assuming a circular geometry.<br />
 &nbsp;&nbsp;&nbsp;Roundnesss_cAR: Circularity corrected by aspect ratio, from Y. Takashimizu and M. Iiyoshi, &quot;New parameter of roundness R: circularity corrected by aspect ratio,&quot; Progress in Earth and Planetary Science, vol. 3, no. 1, p. 2, Jan. 2016.
<a href="https://doi.org/10.1186/s40645-015-0078-x"> DOI: 10.1186/s40645-015-0078-x </a><br />
&nbsp;&nbsp;&nbsp;Round end ribbon thickness from repeating half-annulus - like a snake or Loch Ness Monster perhaps (Lee &amp; Jablonski LTSW'94).<br />  &nbsp;&nbsp;&nbsp;Two calculated fiber widths obtained from the fiber length from <a href="http://www.springer.com/us/book/9781461278689">John C. Russ, Computer Assisted Microscopy, page 189.</a><br />
&nbsp;&nbsp;&nbsp;Fiber length from fiber width (Lee and Jablonski LTSW'94; modified from the formula in  <a href="https://www.crcpress.com/The-Image-Processing-Handbook-Seventh-Edition/Russ-Neal/p/book/9781498740265">John C. Russ, Image Processing Handbook 7th Ed.</a> Page 612).<br />
&nbsp;&nbsp;&nbsp;Two estimates of fiber length obtained from the formulas in <a href="http://www.springer.com/us/book/9781461278689">John C. Russ, Computer Assisted Microscopy page, 189.</a><br />
&nbsp;&nbsp;&nbsp;Hexagonal geometries more appropriate to close-packed structures than ellipses.<br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;HexSide = &radic;((2*Areas)/(3*&radic;3)) <br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;HexPerimeter = 6 * HexSide <br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Hexagonal Shape Factor "HSF" = abs(P&sup2;/Area-13.856): Hexagonal Shape Factor from Behndig et al. https://iovs.arvojournals.org/article.aspx?articleid=2122939 and Collin and Grabsch (1982) https://doi.org/10.1111/j.1755-3768.1982.tb05785.x <br />
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Hexagonal Shape Factor Ratio "HSFR" = abs(13.856/(P&sup2;/Area)): as above but expressed as a ratio like circularity, with 1 being an ideal hexagon. <br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;HexPerimeter = 6 * HexSide <br />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Hexagonality = 6 * HexSide/Perimeter <br />
&nbsp;&nbsp;&nbsp;Full Feret coordinate listing using new Roi.getFeretPoints macro function added in ImageJ 1.52m <br />
Preferences are saved in the user IJ_prefs file. Help button provides more information on each measurement.</p>
<p><img src="https://fs.magnet.fsu.edu/~lee/asc/ImageJUtilities/IA_Images/ASC_Extended_Geometries_Menu_721x479_v190905_PAL32.png" alt="ASC_Extended Geometries Menu"> </p>
<p><sub><sup>
 <strong>Legal Notice:</strong> <br />
These macros have been developed to demonstrate the power of the ImageJ macro language and we assume no responsibility whatsoever for its use by other parties, and make no guarantees, expressed or implied, about its quality, reliability, or any other characteristic. On the other hand we hope you do have fun with them without causing harm.
<br />
The macros are continually being tweaked and new features and options are frequently added, meaning that not all of these are fully tested. Please contact me if you have any problems, questions or requests for new modifications.
 </sup></sub>
</p>
