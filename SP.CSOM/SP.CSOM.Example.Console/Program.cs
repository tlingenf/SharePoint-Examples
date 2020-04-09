using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using OfficeDevPnP.Core;
using System.Configuration;
using SPExamples.Console.CodeExamples;

/*
 * ##########################################################################################################
# Disclaimer
# The sample scripts are not supported under any Microsoft standard support program or service.
#
# The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all
# implied warranties including, without limitation, any implied warranties of merchantability or of fitness
# for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and
# documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the
# creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without
# limitation, damages for loss of business profits, business interruption, loss of business information,
# or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, 
# even if Microsoft has been advised of the possibility of such damages.
##########################################################################################################
*/

namespace SPExamples.Console
{
    class Program
    {
        static void Main(string[] args)
        {
            System.Console.ForegroundColor = ConsoleColor.White;
            System.Console.WriteLine("This Sample clones a site using the PnP Provisioning Engine.");
            CloneWorkshopExample.Run();
            System.Console.WriteLine("Press Enter to continue.");
            System.Console.ReadLine();

            System.Console.Clear();
            System.Console.ForegroundColor = ConsoleColor.White;
            System.Console.Write("This Sample adds a new item to a SharePoint list using the current date/time and user.");
            UserCreateItem.Run();
            System.Console.WriteLine("Press Enter to continue.");
            System.Console.ReadLine();

            System.Console.Clear();
            System.Console.ForegroundColor = ConsoleColor.White;
            System.Console.Write("This Sample uses vairous file upload methods to upload large files. This sample will also demonstrate file chunking and throttling.");
            CSOMLargeFileUpload.Run();

            // Pause and modify the UI to indicate that the operation is complete
            System.Console.ForegroundColor = ConsoleColor.White;
            System.Console.WriteLine("We're done. Press Enter to continue.");
            System.Console.ReadLine();
        }
    }
}
