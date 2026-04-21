using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace StudentPlatform.Backend.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddCreatedByFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CreatedById",
                table: "TopicVideos",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CreatedById",
                table: "Topics",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CreatedById",
                table: "Quizzes",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "GradedById",
                table: "AssignmentSubmissions",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CreatedById",
                table: "Assignments",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_TopicVideos_CreatedById",
                table: "TopicVideos",
                column: "CreatedById");

            migrationBuilder.CreateIndex(
                name: "IX_Topics_CreatedById",
                table: "Topics",
                column: "CreatedById");

            migrationBuilder.CreateIndex(
                name: "IX_Quizzes_CreatedById",
                table: "Quizzes",
                column: "CreatedById");

            migrationBuilder.CreateIndex(
                name: "IX_AssignmentSubmissions_GradedById",
                table: "AssignmentSubmissions",
                column: "GradedById");

            migrationBuilder.CreateIndex(
                name: "IX_Assignments_CreatedById",
                table: "Assignments",
                column: "CreatedById");

            migrationBuilder.AddForeignKey(
                name: "FK_Assignments_Users_CreatedById",
                table: "Assignments",
                column: "CreatedById",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_AssignmentSubmissions_Users_GradedById",
                table: "AssignmentSubmissions",
                column: "GradedById",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Quizzes_Users_CreatedById",
                table: "Quizzes",
                column: "CreatedById",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Topics_Users_CreatedById",
                table: "Topics",
                column: "CreatedById",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_TopicVideos_Users_CreatedById",
                table: "TopicVideos",
                column: "CreatedById",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Assignments_Users_CreatedById",
                table: "Assignments");

            migrationBuilder.DropForeignKey(
                name: "FK_AssignmentSubmissions_Users_GradedById",
                table: "AssignmentSubmissions");

            migrationBuilder.DropForeignKey(
                name: "FK_Quizzes_Users_CreatedById",
                table: "Quizzes");

            migrationBuilder.DropForeignKey(
                name: "FK_Topics_Users_CreatedById",
                table: "Topics");

            migrationBuilder.DropForeignKey(
                name: "FK_TopicVideos_Users_CreatedById",
                table: "TopicVideos");

            migrationBuilder.DropIndex(
                name: "IX_TopicVideos_CreatedById",
                table: "TopicVideos");

            migrationBuilder.DropIndex(
                name: "IX_Topics_CreatedById",
                table: "Topics");

            migrationBuilder.DropIndex(
                name: "IX_Quizzes_CreatedById",
                table: "Quizzes");

            migrationBuilder.DropIndex(
                name: "IX_AssignmentSubmissions_GradedById",
                table: "AssignmentSubmissions");

            migrationBuilder.DropIndex(
                name: "IX_Assignments_CreatedById",
                table: "Assignments");

            migrationBuilder.DropColumn(
                name: "CreatedById",
                table: "TopicVideos");

            migrationBuilder.DropColumn(
                name: "CreatedById",
                table: "Topics");

            migrationBuilder.DropColumn(
                name: "CreatedById",
                table: "Quizzes");

            migrationBuilder.DropColumn(
                name: "GradedById",
                table: "AssignmentSubmissions");

            migrationBuilder.DropColumn(
                name: "CreatedById",
                table: "Assignments");
        }
    }
}
