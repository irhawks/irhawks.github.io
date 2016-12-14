import sys
import re
import numpy as np
import matplotlib.pyplot as plt
# every sampled time at 200 ms intervals
t = np.arange(0., 5., 0.2)
# red dashes, blue squares and green triangles
plt.plot(t,t,'r--', t,t**2,'bs', t,t**3,'g^')
plt.savefig('../img/'+re.sub('.py$','.pdf',sys.argv[0]))
